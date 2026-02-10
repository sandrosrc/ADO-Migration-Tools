# Azure DevOps Migration Tools

This project contains a set of scripts to help migrate Azure DevOps projects, including work items, dashboards, queries, libraries, and pipelines from one organization/project to another.

## Prerequisites

- Bash shell environment
- Azure CLI installed and configured
- Appropriate permissions in both source and target Azure DevOps organizations

## Project Structure

- `main.sh` - Main script that orchestrates the migration process
- `setup.sh` - Initial setup and configuration
- `init.sh` - Work Items list initialization
- `variables.sh` - Contains shared variables used across scripts
- `dashboards.sh` - Handles dashboard migration
- `workitems.sh` - Handles work item migration
- `queries.sh` - Handles query migration
- `libraries.sh` - Handles library migration
- `pipelines.sh` - Handles pipeline migration
- `clean.sh` - Cleanup operations

## Usage

1. Open `main.sh` in a text editor
2. Modify the following variables at the top of the file:
   ```bash
   OLD_PROJECT_NAME="your-source-project-name"
   NEW_PROJECT_NAME="your-target-project-name"
   OLD_ORGANIZATION_NAME="your-source-organization"
   NEW_ORGANIZATION_NAME="your-target-organization"
   ```
3. Save the file
4. Run the migration:
   ```bash
   bash main.sh
   ```

## Migration Process

The script will execute the following steps in order:
1. Initial setup and configuration
2. Variable initialization
3. Dashboard migration
4. Work item migration
5. Query migration
6. Library migration
7. Pipeline migration
8. Cleanup operations

## Error Handling

The script includes error handling and will stop if any step fails. Check the error message to identify which step failed and troubleshoot accordingly.

## Notes

- Make sure you have the necessary permissions in both source and target organizations
- The migration process may take some time depending on the amount of data being migrated
- It's recommended to test the migration with a small project first
- Your first retrieve process will take much longer than the next
- If the work items list from the old organization is not retrieved first, the script will automatically fetch it during the migration process

