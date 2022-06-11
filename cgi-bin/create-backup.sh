#!/bin/bash

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" &> /dev/null && pwd)

source "$BASEDIR/.env"

cd "$BASEDIR/"

# If run script with --local, then don't send backup to remote storage
moveToCloud="Y"
while [ $# -gt 0 ] ; do
    case $1 in
        --local) moveToCloud="N";;
    esac
    shift
done

# If backups storage is not mounted, then anyway store backups local
if ! [[ $COMPOSE_FILE == *"compose-cloud.yml"* ]]; then
    moveToCloud="N"
fi

# Current date, 2022-01-25_16-10
timestamp=`date +"%Y-%m-%d_%H-%M"`
backups_local_folder="$BASEDIR/.backups/local"
backups_cloud_folder="$AWS_S3_LOCAL_MOUNT_POINT"

# Creating local folder for backups
mkdir -p "$backups_local_folder"

# Creating backup of application
tar \
	--exclude='vendor' \
    -czvf $backups_local_folder/"$timestamp"_app.tar.gz \
	-C $BASEDIR "app"

# Creating backup of database
docker exec database sh -c "exec mysqldump -u root -h $DB_HOST -p$DB_ROOT_PASSWORD $DB_DATABASE" > $backups_local_folder/"$timestamp"_database.sql
gzip $backups_local_folder/"$timestamp"_database.sql

# If required, then move current backup to cloud storage
if [ $moveToCloud == "Y" ]; then
    mv $backups_local_folder/"$timestamp"_database.sql.gz $backups_cloud_folder/"$timestamp"_database.sql.gz
    mv $backups_local_folder/"$timestamp"_app.tar.gz $backups_cloud_folder/"$timestamp"_app.tar.gz
fi

# If we already moved backup to cloud, then remove old backups (older than 30 days) from cloud storage
if [ $moveToCloud == "Y" ]; then
    /usr/bin/find $backups_cloud_folder/ -type f -mtime +30 -exec rm {} \;
fi
