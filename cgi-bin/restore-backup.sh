#!/bin/bash

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" &> /dev/null && pwd)

source "$BASEDIR/.env"

cd "$BASEDIR/"

backupsDestination="$BASEDIR/.backups/local"

# If backups storage is mounted, ask, from where will restore backups
if [[ $COMPOSE_FILE == *"compose-cloud.yml"* ]]; then
    while true
    do
        reset
        echo "Select backups destination:"
        echo "1. Local;"
        echo "2. Cloud;"
        echo "---------"
        echo "0. Exit"

        read -r choice

        case $choice in
            "0")
                exit
                ;;
            "1")
                break
                ;;
            "2")
                backupsDestination="$AWS_S3_LOCAL_MOUNT_POINT"
                break
                ;;
            *)
                ;;
        esac
    done
fi
reset

# Select backup for restore
echo "Available backups:"
find "$backupsDestination"/*.gz  -printf "%f\n"
echo "------------"
echo "Enter backup path:"

read -i "$backupsDestination"/ -e backup_name

if ! [ -f "$backup_name" ]; then
    echo "Wrong backup path."
    exit 1
fi


backup_mode="unknown"
if [[ $backup_name == *"app.tar.gz"* ]]; then
    backup_mode="app"
elif [[ $backup_name == *"database.sql.gz"* ]]; then
    backup_mode="database"
fi

if [ $backup_mode == "unknown" ]; then
    echo "Unknown backup type"
    exit 1
fi

reset

if [ $backup_mode == "app" ]; then
    mkdir -p "$BASEDIR"/.backups/tmp
    cp "$backup_name" "$BASEDIR"/.backups/tmp/app_tmp.tar.gz

    tar -xvf "$BASEDIR"/.backups/tmp/app_tmp.tar.gz -C "$BASEDIR"

    rm -rf "$BASEDIR"/.backups/tmp
fi

if [ $backup_mode == "database" ]; then
    mkdir -p "$BASEDIR"/.backups/tmp
    cp "$backup_name" "$BASEDIR"/.backups/tmp/database_tmp.sql.gz

    gunzip "$BASEDIR"/.backups/tmp/database_tmp.sql.gz

    if ! [ -f "$BASEDIR"/.backups/tmp/database_tmp.sql ]; then
        echo "Error in database unpack process"
        exit 1
    fi

    docker-compose exec db bash -c "exec mysql -u root -p$DB_ROOT_PASSWORD $DB_DATABASE < /var/www/.backups/tmp/database_tmp.sql"

    rm -rf "$BASEDIR"/.backups/tmp
fi
