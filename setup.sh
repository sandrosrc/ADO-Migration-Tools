#!/bin/bash

set -e

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

OLD_PROJECT_NAME=$(grep "^OLD_PROJECT_NAME=" main.sh | sed 's/OLD_PROJECT_NAME="\(.*\)"/\1/' | sed 's/ /%20/g')
NEW_PROJECT_NAME=$(grep "^NEW_PROJECT_NAME=" main.sh | sed 's/NEW_PROJECT_NAME="\(.*\)"/\1/' | sed 's/ /%20/g')
OLD_ORGANIZATION_NAME=$(grep "^OLD_ORGANIZATION_NAME=" main.sh | sed 's/OLD_ORGANIZATION_NAME="\(.*\)"/\1/')
NEW_ORGANIZATION_NAME=$(grep "^NEW_ORGANIZATION_NAME=" main.sh | sed 's/NEW_ORGANIZATION_NAME="\(.*\)"/\1/')

if [ -z "$OLD_PROJECT_NAME" ]; then
    echo "Error: OLD_PROJECT_NAME from main.sh is not defined properly"
    exit 1
fi

if [ -z "$NEW_PROJECT_NAME" ]; then
    echo "Error: NEW_PROJECT_NAME from main.sh is not defined properly"
    exit 1
fi

if [ -z "$OLD_ORGANIZATION_NAME" ]; then
    echo "Error: OLD_ORGANIZATION_NAME from main.sh is not defined properly"
    exit 1
fi

if [ -z "$NEW_ORGANIZATION_NAME" ]; then
    echo "Error: NEW_ORGANIZATION_NAME from main.sh is not defined properly"
    exit 1
fi

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq first."
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    exit 1
fi

if ! az extension show --name azure-devops &> /dev/null; then
    echo "Azure DevOps extension not found. Installing..."
    az extension add --name azure-devops
fi

if [ ! -f .azure/old_pat.txt ] || [ ! -f .azure/new_pat.txt ]; then
    echo "Error: PAT files not found in ~/.azure/"
    echo "Please create .azure/old_pat.txt and .azure/new_pat.txt with your PATs"
    exit 1
fi

if [ ! -s .azure/old_pat.txt ] || [ ! -s .azure/new_pat.txt ]; then
    echo "Error: One or both PAT files are empty"
    echo "Please ensure both .azure/old_pat.txt and .azure/new_pat.txt contain valid PATs"
    exit 1
fi

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

OLD_PAT=$(cat .azure/old_pat.txt)
NEW_PAT=$(cat .azure/new_pat.txt)

rm -rf $OLD_PROJECT_NAME
mkdir $OLD_PROJECT_NAME
mkdir $OLD_PROJECT_NAME/Dashboards
mkdir $OLD_PROJECT_NAME/WorkItems
mkdir $OLD_PROJECT_NAME/Queries
mkdir $OLD_PROJECT_NAME/Variables
mkdir $OLD_PROJECT_NAME/Pipelines
mkdir $OLD_PROJECT_NAME/.setup

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

##### GET OLD PROJECT ID #####
curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/_apis/projects?api-version=7.1-preview.4" \
     -o $OLD_PROJECT_NAME/.setup/old-project-list.json >/dev/null 2>&1

jq . $OLD_PROJECT_NAME/.setup/old-project-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/old-project-list.json
jq '(.value[].name) |= gsub(" "; "%20")' $OLD_PROJECT_NAME/.setup/old-project-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/old-project-list.json

##### GET NEW PROJECT ID #####
curl -u :$NEW_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/_apis/projects?api-version=7.1-preview.4" \
     -o $OLD_PROJECT_NAME/.setup/new-project-list.json >/dev/null 2>&1

jq . $OLD_PROJECT_NAME/.setup/new-project-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/new-project-list.json
jq '(.value[].name) |= gsub(" "; "%20")' $OLD_PROJECT_NAME/.setup/new-project-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/new-project-list.json

##### GET OLD REPOSITORY ID #####
curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/${OLD_PROJECT_NAME}/_apis/git/repositories?includeLinks=false&includeAllUrls=false&includeHidden=true&api-version=7.1-preview.1" \
     -o $OLD_PROJECT_NAME/.setup/old-repo-list.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/.setup/old-repo-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/old-repo-list.json

##### GET NEW REPOSITORY ID #####
curl -u :$NEW_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${NEW_ORGANIZATION_NAME}/${NEW_PROJECT_NAME}/_apis/git/repositories?includeLinks=false&includeAllUrls=false&includeHidden=true&api-version=7.1-preview.1" \
     -o $OLD_PROJECT_NAME/.setup/new-repo-list.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/.setup/new-repo-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/new-repo-list.json

OLD_PROJECT_ID=$(jq -r --arg name "$OLD_PROJECT_NAME" '.value[] | select(.name == $name) | .id' $OLD_PROJECT_NAME/.setup/old-project-list.json)

if [ -z "$OLD_PROJECT_ID" ]; then
    echo "Error: Could not find project ID for project name: $OLD_PROJECT_NAME"
    exit 1
fi

##### GET OLD PROJECT'S TEAMS LIST #####
curl -u :$OLD_PAT \
     -H "Accept: application/json" \
     -X GET \
     "https://dev.azure.com/${OLD_ORGANIZATION_NAME}/_apis/projects/${OLD_PROJECT_ID}/teams?\$mine=false&\$top=200&\$skip=0&\$expandIdentity=false&api-version=7.1-preview.3" \
     -o $OLD_PROJECT_NAME/.setup/old-project-team-list.json >/dev/null 2>&1
jq . $OLD_PROJECT_NAME/.setup/old-project-team-list.json > temp.json && mv temp.json $OLD_PROJECT_NAME/.setup/old-project-team-list.json

echo "Initial setup completed"

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################
