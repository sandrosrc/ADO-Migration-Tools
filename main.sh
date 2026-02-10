#!/bin/bash

# Exit on error
set -e

##########################################################################################
################################ /!\ ONLY CHANGE THIS /!\ ################################
##########################################################################################

OLD_PROJECT_NAME="your-source-project-name"
NEW_PROJECT_NAME="your-target-project-name"

OLD_ORGANIZATION_NAME="your-source-organization"
NEW_ORGANIZATION_NAME="your-target-organization"

##########################################################################################
################################## LAUNCHING OPERATIONS ##################################
##########################################################################################

bash setup.sh || { echo "Error: Initial setup failed"; exit 1; }
bash variables.sh || { echo "Error: Variables.sh failed"; exit 1; }

if [ ! -f ".init/WorkItems/.done" ]; then
    bash init.sh || { echo "Error: Initialization failed"; exit 1; }
else
    echo "Work Items list retrieved"
fi

bash dashboards.sh || { echo "Error: Failed to retrieve dashboards"; exit 1; }
bash workitems.sh || { echo "Error: Failed to retrieve workitems"; exit 1; }
bash queries.sh || { echo "Error: Failed to retrieve queries"; exit 1; }
bash libraries.sh || { echo "Error: Failed to retrieve libraries"; exit 1; }
bash pipelines.sh || { echo "Error: Failed to retrieve pipelines"; exit 1; }
bash clean.sh || { echo "Error: Failed to clean up"; exit 1; }
