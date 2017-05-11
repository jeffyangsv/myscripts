#!/bin/bash
##################################################
#Name:        mysql_sync_master.sh
#Version:     v3.0
#Create_Date: 2017-2-18
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Mysql一键备份主库脚本"
##################################################

#variable
MYUSER=root
MYPASS=123456
#MYSOCK=/App/data/3306/mysql.sock
MYSOCK=/var/lib/mysql/mysql.sock
MAIN_PATH=/App/backup/mysql
DATA_PATH=/App/backup/mysql
LOG_FILE=${DATA_PATH}/mysqllogs_`date +%F`.log
DATA_FILE=${DATA_PATH}/mysql_backup_`date +%F`.sql.gz
MYSQL_PATH=/usr/bin
#mysql_mster_backup
MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"
#$MYSQL_CMD -e "grant replication slave on *.* to 'slave'@'%' indentified by '123456';"

##Old version
#MYSQL_DUMP='$MYSQL_PATH/mysqldump -u$MYUSER -pMYPASS -S $MYSOCK -A -B --single-transaction -e' 
#cat | $MYSQL_CMD <<EOF
#flush table with lock;
#system echo "---show master status result---" >>$LOG_FILE
#system $MYSQL_CMD -e 'show master status' | tail -1  >>$LOG_FILE
#system ${MYSQL_DUMP} | gzip >  $DATA_FILE
#EOF
#$MYSQL_CMD -e 'unlock tables;'

#New Version
MYSQL_DUMP="$MYSQL_PATH/mysqldump -u$MYUSER -p$MYPASS -S $MYSOCK -A -B --master-data=1 --single-transaction -e"
$MYSQL_CMD -e "show master status"|tail -1 > $LOG_FILE
$MYSQL_DUMP|gzip > $DATA_FILE

