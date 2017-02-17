#!/bin/bash
##################################################
#Name:        cheak_mysql_slave_status.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Check_MySQL_Slave_Status"
##################################################

#crontab time 00:10
MYSQLPORT=`netstat -na|grep "LISTEN"|grep "3306"|awk -F[:" "]+ '{print $5}'`
MYSQLIP=`ifconfig eth0|grep "inet " | awk -F[" "]+ '{print $3}'`
STATUS=$(/usr/bin/mysql -u root -p123456 -S /var/lib/mysql/mysql.sock -e "show slave status\G" | grep -i "running") 
IO_env=`echo $STATUS | grep IO | awk  ' {print $2}'`
SQL_env=`echo $STATUS | grep SQL | awk  '{print $2}'`
DATA=`date +"%y-%m-%d %H:%M:%S"`
if [ "$MYSQLPORT" == "3306" ]
then
  echo "mysql is running"
else
  mail -s "warn!server: $MYSQLIP mysql is down" glk73748196@sina.com
fi
if [ "$IO_env" = "Yes" -a "$SQL_env" = "Yes" ]
then
  echo "Slave is running!"
else
  echo "####### $DATA #########"  >> /var/log/mysql/check_mysql_slave.log
  echo "Slave is not running!"    >> /var/log/mysql/check_mysql_slave.log
  echo "Slave is not running!" | mail -s "warn! $MYSQLIP MySQL Slave is not running" glk73748196@sina.com
fi

