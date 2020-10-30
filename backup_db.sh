#!/bin/bash

#     _       _       _   _             
#    (_) ___ | |_   _| |_(_) ___  _ __  
#    | |/ _ \| | | | | __| |/ _ \| '_ \ 
#    | | (_) | | |_| | |_| | (_) | | | |
#   _/ |\___/|_|\__,_|\__|_|\___/|_| |_|
#  |__/                                 
#
# Backup/MySQL
# v0.1
# Alpha Version, not for production systems

# keep one daily backup for each of the last 7 days
# At 04:00
# 0 4   *   *   *   /backup/backup_db.sh daily

# keep one weekly backup for each of the last 4 weeks
# At 05:00 on Sunday.
# 0 5 * * 0 /backup/backup_db.sh weekly

# keep one monthly backup for each of the last 6 months
# At 03:00 on day-of-month 1
# 0 3 1 * * /backup/backup_db.sh monthly

# keep one yearly backup for each year
# At 02:00 on day-of-month 1 in January
# 0 2 1 1 * /backup/backup_db.sh yearly

if [ $# -lt 1 ]; then
	echo "usage: $0 <daily|weekly|monthly|yearly>"
	exit 1
fi

# General settings

HOST_DB=127.0.0.1
CUSTOMERLIST=folder_name_here
PERIOD=$1

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
    
    eval "$(egrep -v '^#' .env | xargs)"

    FILE_PREFIX=`date +\%Y-\%m-\%d_\%H-\%M-\%S`
    BACKUP_DIR="/backup/customer/${CUSTOMER}/mysql/${PERIOD}/"

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

    # Generate Folder (if it doesnt exist)
    mkdir -p "${BACKUP_DIR}"

    # Dumb the databases in seperate names and gzip the .sql file
    for db in $databases; do
        #mysqldump -h ${HOST_DB} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${db} > $BACKUP_DIR/$DATE/${FILE_PREFIX}_${db}.sql;
        mysqldump -h ${HOST_DB} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${db} | gzip > $BACKUP_DIR/${FILE_PREFIX}_${db}.sql.gz;
    done

}
 
# Use space as separator and apply as pattern
for CUSTOMER in ${CUSTOMERLIST// / }
do
   backup $CUSTOMER
done