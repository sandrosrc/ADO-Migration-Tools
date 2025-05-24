#!/bin/bash

set -e

rm -rf $OLD_PROJECT_NAME/.setup
rm -f $OLD_PROJECT_NAME/WorkItems/WorkItems-List.json
rm -f $OLD_PROJECT_NAME/WorkItems/all-ids.txt
rm -f $OLD_PROJECT_NAME/Queries/queries-id.txt
rm -f $OLD_PROJECT_NAME/Queries/queries.json
rm -f $OLD_PROJECT_NAME/Dashboards/dashboards.json
rm -f $OLD_PROJECT_NAME/Variables/variables-list.json
rm -f $OLD_PROJECT_NAME/Pipelines/pipelines.json
