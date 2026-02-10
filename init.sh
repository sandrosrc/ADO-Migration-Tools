#!/bin/bash

source variables.sh
set -e

############################################################
################### RETRIEVE WORKITEMS #####################
############################################################

curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -H "Content-Type: application/json" \
     -X POST \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/${OLD_TEAM_ID_1}/_apis/wit/wiql?api-version=7.1-preview.2" \
     -d '{"query": "SELECT [Id] from WorkItems"}' \
     -o .init/WorkItems/WorkItems-List.json >/dev/null 2>&1

jq -r '.workItems[].id' .init/WorkItems/WorkItems-List.json > .init/WorkItems/all-ids.txt
echo "Work Items list retrieved"

split_workitem_ids() {
     local input_file=".init/WorkItems/all-ids.txt"
     local output_prefix=".init/WorkItems/WorkItems-IDs-part-"
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
         -o .init/WorkItems/item-$id.json >/dev/null 2>&1

    jq . .init/WorkItems/item-$id.json > .init/temp-$id.json && mv .init/temp-$id.json .init/WorkItems/item-$id.json
}

total=$(wc -l < .init/WorkItems/all-ids.txt)
per_file=$(( (total + 99) / 100 ))

split_workitem_ids

for file in .init/WorkItems/WorkItems-IDs-part-*.json; do
     while IFS= read -r id; do
          run_command "$id" "$file" &
          while (( $(jobs -r | wc -l) >= 100 )); do
               sleep 0.1
          done
     done < "$file"
     rm -f "$file"
done
wait

touch .init/WorkItems/.done

echo "All work items retrieved, launching main.sh"