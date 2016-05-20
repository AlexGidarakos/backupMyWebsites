#!/bin/bash
#
# backupMyWebsites.sh
# A Bash script for unattended backups of multiple websites on a LEMP server
# Project URL: https://github.com/AlexGidarakos/backupMyWebsites
# Version: 0.1.1
#
# backupMyWebsites.sh is designed to run with root privileges from a daily
# cronjob and create daily, weekly and monthly backups of our websites.
# For each website, a configuration file with a .conf extension must be
# created inside the conf.d subdirectory. See conf.d/example.com.conf.README
# for an example.
# Dependencies: Bash, GNU coreutils, systemd, nginx, php5-fpm, rsync,
# mysqldump, gzip. With some modifications, it should work for other shells,
# init systems, Apache instead of nginx etc.
# Tested on: Debian GNU/Linux 8.4 amd64
#
# Copyright 2016, Alexandros Gidarakos.
# Author: Alexandros Gidarakos <algida79@gmail.com>
# Author URL: http://linkedin.com/in/alexandrosgidarakos
#
# SPDX-License-Identifier: GPL-2.0

# Check for root priviliges
if [[ $(whoami) != "root" ]]; then
    echo "This script should only be run as root - Exiting..."
    exit 1
fi

# Store script's basedir
BMW_DIR=$(dirname $(realpath $0))

#Store script's log file path
BMW_LOG=$BMW_DIR/backupMyWebsites.log

# Logging function
bmwLog () { echo $(date +%Y-%m-%d\ %H:%M:%S) - $1 >> $BMW_LOG; }

# This function starts a timer
bmwTimerStart () { BMW_TIME_1=$(date +%s); }

# This function stops the timer and stores result in $BMW_DURATION as seconds
bmwTimerStop () { BMW_TIME_2=$(date +%s); BMW_DURATION=$((BMW_TIME_2-BMW_TIME_1)); }

# This function brings the web stack down for backup consistency
bmwStackDown () {
    bmwLog "Stopping nginx"
    systemctl stop nginx
    bmwLog "Stopping php5-fpm"
    systemctl stop php5-fpm
}

# This function brings the web stack up again
bmwStackUp () {
    bmwLog "Starting php5-fpm"
    systemctl start php5-fpm
    bmwLog "Starting nginx"
    systemctl start nginx
}

bmwLog "Invoked"

# Loop over configuration files
for BMW_CONF_FILE in $BMW_DIR/conf.d/*; do
    # Ignore files not ending with .conf
    if [[ ${BMW_CONF_FILE##*.} != "conf" ]]; then continue; fi

    # Clear configuration variables from previous loop iteration
    unset BMW_SITE
    unset BMW_SITE_DIR
    unset BMW_BACKUP_DIR
    unset BMW_SITE_EXCLUDE
    unset BMW_SITE_DB

    # Load configuration variables from file
    bmwLog "Loading configuration file: $BMW_CONF_FILE"
    source $BMW_CONF_FILE

    # Check if minimum required configuration variables are declared
    if [[ -z $BMW_SITE ]] || [[ -z $BMW_SITE_DIR ]] || [[ -z $BMW_SITE_BACKUP_DIR ]]; then
        bmwLog "Bad configuration, ignoring $BMW_CONF_FILE"
        continue
    fi

    bmwLog "Found website $BMW_SITE in $BMW_SITE_DIR"

    # Loop over daily-weekly-monthly backup ages
    for BMW_FREQ in daily weekly monthly; do
        if [[ $BMW_FREQ == "weekly" && $(date +%w) != "1" ]] || \
           [[ $BMW_FREQ == "monthly" && $(date +%d) != "01" ]]; then
            continue
        fi

        bmwLog "Starting $BMW_FREQ backup"

        # Create target directory if it doesn't exist
        BMW_TARGET=$BMW_SITE_BACKUP_DIR/$BMW_FREQ
        mkdir -p $BMW_TARGET

        # If daily backup
        if [[ $BMW_FREQ == "daily" ]]; then
            # Create temporary file for the exclude list
            BMW_SITE_EXCLUDE_FILE=$(mktemp)
            touch $BMW_SITE_EXCLUDE_FILE

            for ITEM in $BMW_SITE_EXCLUDE; do
                echo $ITEM >> $BMW_SITE_EXCLUDE_FILE
            done

            # Backup website files
            bmwStackDown
            bmwLog "Starting file backup"
            bmwTimerStart
            rsync -av -L --delete-excluded --progress --exclude-from $BMW_SITE_EXCLUDE_FILE $BMW_SITE_DIR/ $BMW_TARGET

            # Touch target dir to reflect backup date
            touch $BMW_TARGET

            bmwTimerStop
            bmwLog "File backup completed in $BMW_DURATION seconds"

            # Remove temporary file for the exclude list
            rm -f $BMW_SITE_EXCLUDE_FILE

            # Backup website database, if applicable
            if [[ -n $BMW_SITE_DB ]]; then
                bmwLog "Starting database backup"
                bmwTimerStart
                mysqldump $BMW_SITE_DB | gzip -9 > $BMW_TARGET/db.sql.gz
                bmwTimerStop
                bmwLog "Database backup completed in $BMW_DURATION seconds"
            fi

            # Bring the web stack up again
            bmwStackUp
        # Else, we simply rsync from a just completed daily backup
        else
            bmwTimerStart
            rsync -av --delete --progress $BMW_SITE_BACKUP_DIR/daily/ $BMW_TARGET
            touch $BMW_TARGET
            bmwTimerStop
            bmwLog "$BMW_FREQ backup completed in $BMW_DURATION seconds"
        fi
    done

    bmwLog "Backup of $BMW_SITE completed"
# Done with this website
done

# Log an exit message
bmwLog "Done"
