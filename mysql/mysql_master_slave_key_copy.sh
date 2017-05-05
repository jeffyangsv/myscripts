#!/bin/bash
##################################################
#Name:        mysql_mater_slave_copy.sh
#Version:     v3.0
#Create_Date: 2017-2-18
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Mysql不停主库,批量部署从库脚本"
#Note:        "需要把主库上的备份文件拷贝过来"
##################################################
MASTER_IP='172.16.1.100'
MYUSER=root
MYPASS=123456
#MYSOCK=/App/data/3306/mysql.sock
MYSOCK=/var/lib/mysql/mysql.sock
MAIN_PATH=/App/backup/mysql
DATA_PATH=/App/backup/mysql
LOG_FILE=${DATA_PATH}/mysqllog_`date +%F`.log
LOG_SLAVE=${DATA_PATH}/mysql_slave_`date +%F`.log
DATA_FILE=${DATA_PAH}/mysql_backup_`date +%F`.sql.gz
MYSQL_PATH=/usr/bin
MYSQL_CMD="$MYSQL_PATH/mysql -u$MYUSER -p$MYPASS -S $MYSOCK"

#recover_mysql_slave
cd $DATA_PATH
gzip -d mysql_backup_`date +%F`.sql.gz
$MYSQL_CMD < mysql_backup_`date +%F`.sql

#configure slave
$MYSQL_CMD -e "CHANGE MASTER TO MASTER_HOST='$MASTER_IP',MASTER_PORT=3306,MASTER_USER='slave',MASTER_PASSWORD='123456';"
$MYSQL_CMD -e "start slave;"
$MYSQL_CMD -e "show slave status\G"| egrep "IO_Running|SQL_Running" > $LOG_SLAVE
mail -s "MySQL slave result"  glk73748196@sina.com <$LOG_SLAVE
#如果执行不成功,可以手动重新做从库
#LOG_FILE=`cat $LOG_FILE | awk '{print $1}'`
#LOG_POS=`cat $LOG_FILE | awk '{print $2}'`
#CHANGE_SQL="CHANGE MASTER TO MASTER_HOST='$MASTER_IP',MASTER_PORT=3306,MASTER_USER='slave',MASTER_PASSWORD='123456',MASTER_LOG_FILE='$LOG_FILE',MASTER_LOG_POS=$LOG_POS;"
#$MYSQL_CMD -e "$CHANGE_SQL"
