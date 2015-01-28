#!/bin/bash
#
# MySQL Backup Script
#  Dumps mysql databases to a file for another backup tool to pick up.
#
# MySQL code:
# GRANT SELECT, RELOAD, LOCK TABLES ON *.* TO 'user'@'localhost'
# IDENTIFIED BY 'password';
# FLUSH PRIVILEGES;
#
##### START CONFIG ###################################################

USER=mysqldump
#PASS=dumbpassword
DIR=/cul/backup/mysql
ROTATE=3

PREFIX=mysql_backup_

EVENTS="--ignore-table=mysql.event"


##### STOP CONFIG ####################################################
PATH=/usr/bin:/usr/sbin:/bin:/sbin



set -o pipefail

cleanup()
{
    find "${DIR}/" -maxdepth 1 -type f -name "${PREFIX}*.sql*" -mtime +${ROTATE} -print0 | xargs -0 -r rm -f
}

mysql --defaults-file=~mysqldump/.my.cnf -s -r -N -e 'SHOW DATABASES' | while read dbname
do
  mysqldump --defaults-file=~mysqldump/.my.cnf --opt --flush-logs --single-transaction \
    ${EVENTS} \
    ${dbname} | bzcat -zc > ${DIR}/${PREFIX}${dbname}_`date +%Y-%m-%d`.sql.bz2
done

/bin/rm ${DIR}/${PREFIX}mysql_current.sql.bz2 
/bin/ln ${DIR}/${PREFIX}mysql_`date +%Y-%m-%d`.sql.bz2 ${DIR}/${PREFIX}mysql_current.sql.bz2 

if [ $? -eq 0 ] ; then
    cleanup
fi
