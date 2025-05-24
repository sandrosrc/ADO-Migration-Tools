#!/bin/bash

source variables.sh
set -e

############################################################
################### GET ALL VARIABLES ######################
############################################################

#####  Only if needed #####
# az extension add --name azure-devops

az pipelines variable-group list --org=$OLD_ORGANIZATION_ID --project=$OLD_PROJECT_ID --query-order Asc --output table | awk 'NR>2 {print $1}' > $OLD_PROJECT_NAME/Variables/variables-list.json

while read -r id; do
    az pipelines variable-group show --org=$OLD_ORGANIZATION_ID --project=$OLD_PROJECT_ID --group-id $id > $OLD_PROJECT_NAME/Variables/variables-$id.json 
    VARIABLE_GROUP_NAME=$(jq -r '.name' $OLD_PROJECT_NAME/Variables/variables-$id.json) 
    VARIABLES=$(jq -r '.variables | to_entries | map("\(.key)=\(.value.value)") | join(" ")' $OLD_PROJECT_NAME/Variables/variables-$id.json)
    az pipelines variable-group create --org=$NEW_ORGANIZATION_ID --project=$NEW_PROJECT_ID --name $VARIABLE_GROUP_NAME --variables $VARIABLES >/dev/null 2>&1
done < $OLD_PROJECT_NAME/Variables/variables-list.json

echo "Libraries uploaded"

