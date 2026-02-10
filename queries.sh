#!/bin/bash

set -e
source variables.sh


############################################################
#################### RETRIEVE QUERIES ######################
############################################################

curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/wit/queries?\$expand=wiql&\$depth=2&\$includeDeleted=true&api-version=7.1-preview.2" \
     -o $OLD_PROJECT_NAME/Queries/queries.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/Queries/queries.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Queries/queries.json

echo "Queries list retrieved"

############################################################
##################### UPLOAD QUERIES #######################
############################################################

jq -r '.value[] | if has("children") then .children[].id else .id end' $OLD_PROJECT_NAME/Queries/queries.json > $OLD_PROJECT_NAME/Queries/queries-id.txt 
awk '{printf "%s ", $0}' $OLD_PROJECT_NAME/Queries/queries-id.txt | sed 's/ *$//' > temp.json && mv temp.json $OLD_PROJECT_NAME/Queries/queries-id.txt

echo "Queries retrieved"

while read -r id; do
     OLD_ID=""
     NEW_ID=""

     curl -u :$OLD_PAT \
          -H "Content-Type: application/json" \
          -X GET \
          "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/wit/queries/${id}?\$expand=wiql&\$depth=2&\$includeDeleted=true&\$useIsoDateFormat=true&api-version=7.1-preview.2" \
          -o $OLD_PROJECT_NAME/Queries/query-$id.json  >/dev/null 2>&1

     OLD_ID=$(jq -r '.id' $OLD_PROJECT_NAME/Queries/query-$id.json) 
     jq '{name, wiql}' $OLD_PROJECT_NAME/Queries/query-$id.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Queries/query-$id.json

     curl -u :$NEW_PAT \
          -H "Content-Type: application/json" \
          -d @$OLD_PROJECT_NAME/Queries/query-$id.json \
          -X POST \
          "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/${NEW_PROJECT_NAME}/_apis/wit/queries/Shared%20Queries?api-version=7.2-preview.2" \
          -o $OLD_PROJECT_NAME/Queries/new-query-$id.json >/dev/null 2>&1

     jq . $OLD_PROJECT_NAME/Queries/new-query-$id.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Queries/new-query-$id.json
     NEW_ID=$(jq -r '.id' $OLD_PROJECT_NAME/Queries/new-query-$id.json)

     ##### Replace old queries ID with new ID #####
     for file in $OLD_PROJECT_NAME/Dashboards/dashboard-*.json; do
          if grep -q "$OLD_ID" $file; then
               sed -i -e "s/$OLD_ID/$NEW_ID/g" $file
          fi
     done
done < <(tr ' ' '\n' < $OLD_PROJECT_NAME/Queries/queries-id.txt) 

echo "Queries uploaded"

############################################################
################### UPLOAD DASHBOARDS ######################
############################################################

##### This is normal, you have to upload queries before uploading dashboards #####
for id in $(jq -r '[.value[].id] | join(" ")' $OLD_PROJECT_NAME/Dashboards/dashboards.json); do
     curl -u :$NEW_PAT \
          -H "Content-Type: application/json" \
          -d @$OLD_PROJECT_NAME/Dashboards/dashboard-$id.json \
          -X POST \
          "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/${NEW_PROJECT_NAME}/_apis/dashboard/dashboards?api-version=7.2-preview.3" \
          -o $OLD_PROJECT_NAME/Dashboards/new-dashboard-$id.json >/dev/null 2>&1
done

echo "Dashboards uploaded"

