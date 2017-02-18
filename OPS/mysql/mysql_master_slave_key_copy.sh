#!/bin/bash
##################################################
#Name:        mysql_mater_slave_copy.sh
#Version:     v3.0
#Create_Date: 2017-2-18
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Mysql不停主库,批量部署从库脚本"
##################################################
MYUSER=root
MYPASS=123456
#MYSOCK=/App/data/3306/mysql.sock
MYSOCK=/var/lib/mysql/mysql.sock
MAIN_PATH=/App/backup/mysql
DATA_PATH=/App/backup/mysql
LOG_FILE=${DATA_PATH}/mysql_slave_copy_`date +%F`.log
DATA_FILE=${DATA_PAH}/mysql_backup_`date +%F`.sql.gz
MYSQL_PATH=/usr/bin
MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"

#recover_mysql_slave
cd $DATA_PATH
gzip -d mysql_backup_`date +%F`.sql.gz
$MYSQL_CMD < mysql_backup_`date +%F`.sql

#configure slave
$MYSQL_CMD -e "CHANGE MASTER TO MASTER_HOST='172.16.1.100',MASTER_PORT=3306,MASTER_USER='slave',MASTER_PASSWORD='123456';"
echo 'chang slave ok'
$MYSQL_CMD -e "start slave;"
$MYSQL_CMD -e "show slave status\G"| egrep "IO_Running|SQL_Running" > $LOG_FILE
mail -s "MySQL slave result"  glk73748196@sina.com <$LOG_FILE
