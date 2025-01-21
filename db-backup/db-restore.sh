#!/bin/bash

ENV_FILE="$(dirname "$0")/.env"  # Get the path of the .env file relative to the script

# Load environment variables from .env file
if [ ! -f "$ENV_FILE" ]; then
    echo ".env file not found!"
    exit 1
fi


# Load environment variables from .env file
set -a
source "$ENV_FILE"
set +a

# Function to display help
function show_help {
    echo "Usage: $0 <backup_file.sql>"
    echo
    echo "Restores a MariaDB backup from the specified SQL file."
    echo
    echo "Arguments:"
    echo "  backup_file.sql   The path to the backup SQL file to restore."
    echo
    echo "If no argument is provided, the script will list available backup files in $BACKUP_DIR."
    echo
    echo "Example:"
    echo "  $0 /tmp/backup/all_databases_20230101_120000.sql"
}

# Check if a backup file was provided
if [ "$#" -eq 1 ]; then
    BACKUP_FILE="$1"
elif [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
    show_help
    exit 1
else
    echo "Available backup files in $BACKUP_DIR:"
    ls -alh "$BACKUP_DIR"/*.sql 2>/dev/null

    # Prompt user to choose a file
    echo "Please enter the name of the backup file to restore (full path):"
    read -r BACKUP_FILE

    # Check if the file exists
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: File '$BACKUP_FILE' does not exist."
        exit 1
    fi
fi

# Restore the backup using mariadb
podman exec -i "$DB_CONTAINER_NAME" sh -c "mariadb -u $DB_USER -p$DB_PASSWORD" < "$BACKUP_FILE"

# Check if the restore was successful
if [ $? -eq 0 ]; then
    echo "Restore successful!"
else
    echo "Restore failed!"
fi
