#!/bin/bash
##################################################
#Name:        mysql_slow_backup.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "备份mysql的slow.log文件"
##################################################
passwd=123456
user=root
mysqlconn="mysql -u$user -p$passwd"
show_slow="show variables like '%slow%';"
#$mysqlconn -e "$show_slow"
$mysqlconn -e  "set global slow_query_log=0;"
mv /var/lib/mysql/slow.log /var/lib/mysql/slow_`date +%F-%H-%M-%S`.log
$mysqlconn -e "set global slow_query_log=1;"
