#!/bin/bash

source variables.sh
set -e

# Create variable with spaces instead of %20
OLD_PROJECT_NAME_SPACES=$(echo "$OLD_PROJECT_NAME" | sed 's/%20/ /g')

############################################################
################### RETRIEVE WORKITEMS #####################
############################################################

curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -X POST \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/${OLD_TEAM_ID_1}/_apis/wit/wiql?api-version=7.1-preview.2" \
     -d '{"query": "SELECT [Id] from WorkItems"}' \
     -o $OLD_PROJECT_NAME/WorkItems/WorkItems-List.json >/dev/null 2>&1

jq -r '.workItems[].id' $OLD_PROJECT_NAME/WorkItems/WorkItems-List.json > $OLD_PROJECT_NAME/WorkItems/all-ids.txt
echo "Work Items list retrieved"

split_workitem_ids() {
     local input_file="$OLD_PROJECT_NAME/WorkItems/all-ids.txt"
     local output_prefix="$OLD_PROJECT_NAME/WorkItems/WorkItems-IDs-part-"
     local total=$(wc -l < "$input_file")
     local per_file=$(( (total + 99) / 100 ))
    
     split -l $per_file "$input_file" "$output_prefix"
    
     local y=1
     for f in $output_prefix*; do
          mv "$f" "$output_prefix$y.json"
          jq -R -s 'split("\n")[:-1]' "$output_prefix$y.json" > temp.json && mv temp.json "$output_prefix$y.json"
          jq -r '.[]' "$output_prefix$y.json" > temp && mv temp "$output_prefix$y.json"
          y=$((y+1))
     done
}

# Function to transform JSON content
transform_json() {
     local file=$1
     local id=$2
     
     # Format JSON and ensure array structure
     jq '.' "$file" > temp-$id.json
     jq '[.]' temp-$id.json > "$file"
     
     sed -i -e "s/${OLD_PROJECT_NAME}/${NEW_PROJECT_NAME}/g" "$file"
     
     jq '.[0] | del(.id, .url, ._links) | {
          "op": "add",
          "path": "/fields/System.Title",
          "value": .fields."System.Title"
     } + . | [.]' "$file" > temp-$id.json && mv temp-$id.json "$file"
     
     rm -f temp-$id.json
}

# Function to map work item types
map_workitem_type() {
    local type=$1
    case $type in
        "User Story")
            echo "User%20Story"
            ;;
        "Test Case")
            echo "Test%20Case"
            ;;
        *)
            echo "$type"
            ;;
    esac
}

run_command() {
     raw_id="$1"
     id=$(echo "$raw_id" | tr -d '\r\n' | xargs)

     if [[ -z "$id" ]]; then
          return
     fi

     curl -u :$OLD_PAT \
          -H "Accept: application/json" \
          -X GET \
          "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/wit/workitems/${id}?api-version=7.1-preview.2" \
          -o $OLD_PROJECT_NAME/WorkItems/item-$id.json >/dev/null 2>&1

     jq . $OLD_PROJECT_NAME/WorkItems/item-$id.json > temp-$id.json && mv temp-$id.json $OLD_PROJECT_NAME/WorkItems/item-$id.json

     if [ "$(jq -r '.fields."System.TeamProject"' $OLD_PROJECT_NAME/WorkItems/item-$id.json)" = "$OLD_PROJECT_NAME" ] || \
     [ "$(jq -r '.fields."System.TeamProject"' $OLD_PROJECT_NAME/WorkItems/item-$id.json)" = "$OLD_PROJECT_NAME_SPACES" ]; then
          WORK_ITEM_TYPE=$(jq -r '.fields."System.WorkItemType"' $OLD_PROJECT_NAME/WorkItems/item-$id.json)
          WORK_ITEM_TYPE=$(map_workitem_type "$WORK_ITEM_TYPE")
          transform_json "$OLD_PROJECT_NAME/WorkItems/item-$id.json" "$id"
     else
          rm -f $OLD_PROJECT_NAME/WorkItems/item-$id.json
          return
     fi

     curl -u :$NEW_PAT \
          -H "Accept: application/json" \
          -H "Content-Type: application/json-patch+json" \
          -d @$OLD_PROJECT_NAME/WorkItems/item-$id.json \
          -X POST \
          "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/${NEW_PROJECT_NAME}/_apis/wit/workitems/\$${WORK_ITEM_TYPE}?bypassRules=true&suppressNotifications=true&api-version=7.1-preview.3" \
          -o $OLD_PROJECT_NAME/WorkItems/new-item-$id.json >/dev/null 2>&1
}

total=$(wc -l < $OLD_PROJECT_NAME/WorkItems/all-ids.txt)
per_file=$(( (total + 99) / 100 ))

split_workitem_ids

for file in $OLD_PROJECT_NAME/WorkItems/WorkItems-IDs-part-*.json; do
     while IFS= read -r id; do
          run_command "$id" "$file" &
          while (( $(jobs -r | wc -l) >= 100 )); do
               sleep 0.1
          done
     done < "$file"
     rm -f "$file"
done
wait

echo "Work items deployed"
