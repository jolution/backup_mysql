#!/bin/bash

#     _       _       _   _             
#    (_) ___ | |_   _| |_(_) ___  _ __  
#    | |/ _ \| | | | | __| |/ _ \| '_ \ 
#    | | (_) | | |_| | |_| | (_) | | | |
#   _/ |\___/|_|\__,_|\__|_|\___/|_| |_|
#  |__/                                 
#
# Backup/MySQL
# v0.2
# Alpha Version, not for production systems

if [ $# -lt 1 ]; then
	echo "usage: $0 <daily|weekly|monthly|yearly>"
	exit 1
fi

# General settings
PERIOD=$1

# MySQL executable locations (no need to change this)
MYSQL=/usr/bin/mysql
MYSQLDUMP=/usr/bin/mysqldump

cd /backup/
if test -f "/backup/.env"
then
    eval "$(egrep -v '^#' .env | xargs)"

    if [ -z "$CUSTOMERLIST" ]
    then
        echo "No Customerlist found, exit"
        exit 1
    fi

else
    echo "/backup/.env doesnt exists, skip backup"
    exit 1
fi

function backup {

    case $PERIOD in

    daily)
        #echo -n "Daily"
        KEEPDAYS=8
        ;;

    weekly)
        #echo -n "Weekly"
        KEEPDAYS=29
        ;;

    monthly)
        KEEPDAYS=$(( ( $(date '+%s') - $(date -d '6 months ago 1 day' '+%s') ) / 86400 ))
        #echo -n "Monthly"
        ;;

    yearly)
        #echo -n "Yearly"
        ;;

    *)
        echo -n "Unkown Period"
        exit 1
        ;;
    esac

    cd /backup/customer/$CUSTOMER/

    if test -f "/backup/customer/$CUSTOMER/.env"
    then
        eval "$(egrep -v '^#' .env | xargs)"
    else
        echo "/backup/customer/$CUSTOMER/.env doesnt exists, skip backup"
        exit 1
    fi

    FILE_PREFIX=`date +\%Y-\%m-\%d_\%H-\%M-\%S`
    BACKUP_DIR="/backup/customer/${CUSTOMER}/mysql/${PERIOD}/"

    # Generate Folder (if it doesnt exist)
    mkdir -p "${BACKUP_DIR}"

    # Skip Databases
    SKIPDATABASES_GENERAL="Database|information_schema|performance_schema|mysql"

    if [ -z "$SKIPDATABASES_CUSTOM" ]
    then
        SKIPDATABASES=$SKIPDATABASES_GENERAL
    else
        SKIPDATABASES="$SKIPDATABASES_GENERAL|$SKIPDATABASES_CUSTOM"
    fi

    if [ -z "$KEEPDAYS" ]
    then
        # Remove files older than X days
        #find $BACKUP_DIR/* -mtime +$RETENTION -delete
        find $BACKUP_DIR -name "*.gz" -type f -mtime +$KEEPDAYS -exec rm -f {} \;
    fi

    # Retrieve a list of all databases
    databases=`$MYSQL -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW DATABASES;" | grep -Ev "($SKIPDATABASES)"`

    # Dumb the databases in seperate names and gzip the .sql file
    for db in $databases; do
        mysqldump --defaults-extra-file=/backup/customer/$CUSTOMER/mysqldump.cnf ${db} | gzip > $BACKUP_DIR/${FILE_PREFIX}_${db}.sql.gz;

        if [ -z "$ZIP_PWD" ]
        then
            mysqldump --defaults-extra-file=/backup/customer/$CUSTOMER/mysqldump.cnf ${db} | gzip | openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -pass pass:"${ZIP_PWD}" -e -out $BACKUP_DIR/${FILE_PREFIX}_${db}.enc.sql.gz
        fi
    done

}
 
# Use space as separator and apply as pattern
for CUSTOMER in ${CUSTOMERLIST// / }
do
   backup $CUSTOMER
done
