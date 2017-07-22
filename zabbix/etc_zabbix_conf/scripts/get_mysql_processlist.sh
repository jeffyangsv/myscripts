#!/bin/sh 
##################################################
#Name:        get_mysql_performance.sh
#Version:     v1.0
#Create_Date：2016-12-16
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Zabbix监控MySQL进程脚本"
##################################################

MYSQL_SOCK="/var/lib/mysql/mysql.sock" 
#MYSQL_PWD=`cat /var/lib/mysql/.mysqlpassword`
MYSQL_USER=root 
MYSQL_PWD=123456
ARGS=1 

#if [ $# -ne "$ARGS" ];then 
#    echo "Please input one arguement:" 
#fi 

case $1 in 
    Query) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK processlist | grep -w "Query" | wc -l` 
            echo $result 
            ;; 
    Sleep) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK processlist | grep -w "Sleep" | wc -l` 
            echo $result 
            ;; 
    Connect) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK processlist | grep -w "Connect" | wc -l` 
            echo $result 
            ;; 
    Binlog) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK processlist | grep -w "Binlog Dump" | wc -l` 
            echo $result 
            ;; 
        *) 
        echo "Usage:$0(Query|Sleep|Connect|Binlog)" 
        ;; 
esac 
