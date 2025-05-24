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

OLD_ORGANIZATION_ID="https://dev.azure.com/$OLD_ORGANIZATION_NAME/"
NEW_ORGANIZATION_ID="https://dev.azure.com/$NEW_ORGANIZATION_NAME/"

OLD_PROJECT_ID=$(jq -r --arg name "$OLD_PROJECT_NAME" '.value[] | select(.name == $name) | .id' $OLD_PROJECT_NAME/.setup/old-project-list.json)
NEW_PROJECT_ID=$(jq -r --arg name "$NEW_PROJECT_NAME" '.value[] | select(.name == $name) | .id' $OLD_PROJECT_NAME/.setup/new-project-list.json)

if [ -z "$OLD_PROJECT_ID" ]; then
    echo "Error: Could not find project ID for project name: $OLD_PROJECT_NAME"
    exit 1
fi

if [ -z "$NEW_PROJECT_ID" ]; then
    echo "Error: Could not find project ID for project name: $NEW_PROJECT_NAME"
    exit 1
fi

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

OLD_REPOSITORY_ID=$(jq -r '.value[0].id' $OLD_PROJECT_NAME/.setup/old-repo-list.json)
NEW_REPOSITORY_ID=$(jq -r '.value[0].id' $OLD_PROJECT_NAME/.setup/new-repo-list.json)

if [ -z "$OLD_REPOSITORY_ID" ]; then
    echo "Error: Could not find repository ID in the old repository list"
    exit 1
fi

if [ -z "$NEW_REPOSITORY_ID" ]; then
    echo "Error: Could not find repository ID in the new repository list"
    exit 1
fi

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

create_team_id_variables() {
    local json_file="$OLD_PROJECT_NAME/.setup/old-project-team-list.json"
    local counter=1
    local found_teams=false
    
    while IFS= read -r team_id; do
        if [ -n "$team_id" ]; then
            eval "OLD_TEAM_ID_$counter=\"$team_id\""
            found_teams=true
            ((counter++))
        fi
    done < <(jq -r '.value[].id' "$json_file")
    
    if [ "$found_teams" = false ]; then
        echo "Error: No team IDs found in $json_file"
        exit 1
    fi
}

create_team_id_variables

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################

OLD_PAT=$(cat .azure/old_pat.txt)
NEW_PAT=$(cat .azure/new_pat.txt)

display_variables() {
    echo ""
    echo "OLD_PROJECT_NAME: $OLD_PROJECT_NAME"
    echo "NEW_PROJECT_NAME: $NEW_PROJECT_NAME"
    echo ""
    echo "OLD_ORGANIZATION_NAME: $OLD_ORGANIZATION_NAME"
    echo "NEW_ORGANIZATION_NAME: $NEW_ORGANIZATION_NAME"
    echo ""
    echo "OLD_ORGANIZATION_ID: $OLD_ORGANIZATION_ID"
    echo "NEW_ORGANIZATION_ID: $NEW_ORGANIZATION_ID"
    echo ""
    echo "OLD_PROJECT_ID: $OLD_PROJECT_ID"
    echo "NEW_PROJECT_ID: $NEW_PROJECT_ID"
    echo ""
    echo "OLD_REPOSITORY_ID: $OLD_REPOSITORY_ID"
    echo "NEW_REPOSITORY_ID: $NEW_REPOSITORY_ID"
    echo ""

    local team_count=$(jq '.value | length' "$OLD_PROJECT_NAME/.setup/old-project-team-list.json")
    for i in $(seq 1 $team_count); do
        var_name="OLD_TEAM_ID_$i"
        echo "$var_name: ${!var_name}"
    done
    
    echo ""
    echo "OLD_PAT: ${OLD_PAT:0:4}...${OLD_PAT: -4}"
    echo "NEW_PAT: ${NEW_PAT:0:4}...${NEW_PAT: -4}"
}

##### USE THIS ONLY FOR DEBUGGING
# display_variables 

##########################################################################################
############################## /!\ DON'T TOUCH ANYTHING /!\ ##############################
##########################################################################################
