#!/bin/bash

source variables.sh
set -e

############################################################
############ GET PIPELINES AND UPLOAD THEM #################
############################################################

curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/pipelines?api-version=7.1-preview.1" \
     -o $OLD_PROJECT_NAME/Pipelines/pipelines.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/Pipelines/pipelines.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Pipelines/pipelines.json

for id in $(jq -r '[.value[].id] | join(" ")' $OLD_PROJECT_NAME/Pipelines/pipelines.json); do
     curl -u :$OLD_PAT \
          -H "Accept: application/json" \
          -X GET \
          "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/pipelines/${id}?api-version=7.1-preview.1" \
          -o $OLD_PROJECT_NAME/Pipelines/pipelines-$id.json >/dev/null 2>&1
     jq --arg NEW_REPOSITORY_ID "$NEW_REPOSITORY_ID" 'del(._links, .url, .id, .revision) | .configuration.repository.id = $NEW_REPOSITORY_ID' $OLD_PROJECT_NAME/Pipelines/pipelines-$id.json > temp.json && mv temp.json $OLD_PROJECT_NAME/Pipelines/pipelines-$id.json

     curl -u :$NEW_PAT \
          -H "Content-Type: application/json" \
          -d @$OLD_PROJECT_NAME/Pipelines/pipelines-$id.json \
          -X POST \
          "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/${NEW_PROJECT_NAME}/_apis/pipelines?api-version=7.1-preview.1" \
          -o $OLD_PROJECT_NAME/Pipelines/new-pipeline-$id.json >/dev/null 2>&1
     jq . $OLD_PROJECT_NAME/Pipelines/new-pipeline-$id.json  > temp.json && mv temp.json $OLD_PROJECT_NAME/Pipelines/new-pipeline-$id.json
done

echo "Pipelines uploaded"

