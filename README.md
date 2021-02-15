# backup db/mysql
Backup Script for Mysql

# Install
* Download files/folder in /backup on your backup server
* After testing, insert the following cron-jobs with `Crontab -e` or https://console.cron-job.org/login (not mine)
* chmod +x backup_db.sh

## keep one daily backup for each of the last 7 days (At 04:00)
0 4   *   *   *   /backup/backup_db.sh daily

## keep one weekly backup for each of the last 4 weeks (At 05:00 on Sunday)
0 5 * * 0 /backup/backup_db.sh weekly

## keep one monthly backup for each of the last 6 months (At 03:00 on day-of-month 1)
0 3 1 * * /backup/backup_db.sh monthly

## keep one yearly backup for each year (At 02:00 on day-of-month 1 in January)
0 2 1 1 * /backup/backup_db.sh yearly
