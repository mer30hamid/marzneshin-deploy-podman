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


DATE=$(date +"%Y%m%d_%H%M%S")  # Current date and time for backup filename

rm -rf $BACKUP_DIR
mkdir -p "$BACKUP_DIR"

# Backup all databases using mariadb-dump
podman exec "$DB_CONTAINER_NAME" sh -c "mariadb-dump -u $DB_USER -p$DB_PASSWORD --all-databases" > "$BACKUP_DIR/all_databases_$DATE.sql"

# Check if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup successful! Backup file is located at: $BACKUP_DIR/all_databases_$DATE.sql"
else
    echo "Backup failed!"
fi
