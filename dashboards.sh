#!/bin/bash

source variables.sh
set -e

############################################################
################### RETRIEVE DASHBOARDS ####################
############################################################

curl -u :$OLD_PAT \
     -H "Content-Type: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/dashboard/dashboards?api-version=7.2-preview.3" \
     -o $OLD_PROJECT_NAME/Dashboards/dashboards.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/Dashboards/dashboards.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Dashboards/dashboards.json

echo "Dashboards list retrieved"

for id in $(jq -r '[.value[].id] | join(" ")' $OLD_PROJECT_NAME/Dashboards/dashboards.json); do
     curl -u :$OLD_PAT \
          -H "Content-Type: application/json" \
          -X GET \
          "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/dashboard/dashboards/${id}?api-version=7.2-preview.3" \
          -o $OLD_PROJECT_NAME/Dashboards/dashboard-$id.json >/dev/null 2>&1

     for ((i=1; ; i++)); do
          eval "current_team=\$OLD_TEAM_ID_${i}"
          if [[ -z "$current_team" ]]; then
               break
          fi
          
          if grep -q "VS402410" "$OLD_PROJECT_NAME/Dashboards/dashboard-$id.json"; then
               rm "$OLD_PROJECT_NAME/Dashboards/dashboard-$id.json"
               curl -u :"$OLD_PAT" \
                    -H "Content-Type: application/json" \
                    -X GET \
                    "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/${current_team}/_apis/dashboard/dashboards/${id}?api-version=7.2-preview.3" \
                    -o "$OLD_PROJECT_NAME/Dashboards/dashboard-$id.json" >/dev/null 2>&1
          else
               break
          fi
     done
     
     jq '.id = ""' $OLD_PROJECT_NAME/Dashboards/dashboard-$id.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Dashboards/dashboard-$id.json
done

echo "Dashboards retrieved"
