#!/bin/bash

source variables.sh
set -e

OLD_PROJECT_NAME_SPACES=$(echo "$OLD_PROJECT_NAME" | sed 's/%20/ /g')

transform_json() {
     local file=$1
     local id=$2
     
     jq '.' "$file" > temp-$id.json
     jq '[.]' temp-$id.json > "$file"
     
     sed -i -e "s/${OLD_PROJECT_NAME}/${NEW_PROJECT_NAME}/g" "$file"
     sed -i -e 's/ModisCloud/AkkodisDevOps/g' "$file"
     sed -i -e 's/modiscloud.net/akkodis.com/g' "$file"
     sed -i -e 's/akkodisgroup.com/akkodis.com/g' "$file"
     
     jq '.[0] | del(.id, .url, ._links) | {
          "op": "add",
          "path": "/fields/System.Title",
          "value": .fields."System.Title"
     } + . | [.]' "$file" > temp-$id.json && mv temp-$id.json "$file"
     
     rm -f temp-$id.json
}

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
     elif [ ! -f ".init/WorkItems/item-$id.json" ]; then
          return
     fi

     if [ "$(jq -r '.fields."System.TeamProject"' .init/WorkItems/item-$id.json 2>/dev/null)" = "$OLD_PROJECT_NAME" ] || \
     [ "$(jq -r '.fields."System.TeamProject"' .init/WorkItems/item-$id.json 2>/dev/null)" = "$OLD_PROJECT_NAME_SPACES" ]; then
          cp .init/WorkItems/item-$id.json $OLD_PROJECT_NAME/WorkItems/item-$id.json
          WORK_ITEM_TYPE=$(jq -r '.fields."System.WorkItemType"' $OLD_PROJECT_NAME/WorkItems/item-$id.json)
          WORK_ITEM_TYPE=$(map_workitem_type "$WORK_ITEM_TYPE")
          transform_json "$OLD_PROJECT_NAME/WorkItems/item-$id.json" "$id"
     else
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

process_chunk() {
    local chunk_file=$1
    while IFS= read -r id; do
        run_command "$id" &
        while (( $(jobs -r | wc -l) >= 100 )); do
            sleep 0.1
        done
    done < "$chunk_file"
    wait
}

total_ids=$(wc -l < .init/WorkItems/all-ids.txt)
chunk_size=$(( (total_ids + 99) / 100))
split -l $chunk_size .init/WorkItems/all-ids.txt .init/WorkItems/chunk_

for chunk in .init/WorkItems/chunk_*; do
    process_chunk "$chunk" &
done

wait

rm -f .init/WorkItems/chunk_*

echo "Work items deployed"
