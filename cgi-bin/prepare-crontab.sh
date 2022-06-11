#!/bin/bash

BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../" &> /dev/null && pwd)

# Load environment variables
source "$BASEDIR"/.env

# Create temporary directory
mkdir -p "$BASEDIR"/.crontab_tmp/

# Copy all crontab files to temporary directory
cp "$BASEDIR"/.crontab/* "$BASEDIR"/.crontab_tmp/

# Set actual app path in crontab files
find "$BASEDIR"/.crontab_tmp/ -name "*.cron" -exec sed -i "s|#APP_PATH#|$BASEDIR|g" {} +

# Set crontab
if [[ $COMPOSE_FILE == *"compose-https.yml"* ]]; then
    find "$BASEDIR"/.crontab_tmp/ -name '*.cron' -exec cat {} \; | crontab -
else
    find "$BASEDIR"/.crontab_tmp/ -name '*.cron' -not -name 'certbot-renew.cron' -exec cat {} \; | crontab -
fi

# Remove temporary directory
rm -rf "$BASEDIR"/.crontab_tmp/
