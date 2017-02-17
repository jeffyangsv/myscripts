#!/bin/sh 
##################################################
#Name:        get_mysql_performance.sh
#Version:     v1.0
#Create_Date：2016-12-16
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Zabbix监控MySQL性能测试脚本"
##################################################

MYSQL_SOCK="/var/lib/mysql/mysql.sock" 
#MYSQL_PWD=`cat /var/lib/mysql/.mysqlpassword` 
MYSQL_USER='root'
MYSQL_PWD='123456'
ARGS=1 
#if [ $# -ne "$ARGS" ];then 
#    echo "Please input one arguement:" 
#fi 
case $1 in 
    Uptime) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK status|cut -f2 -d":"|cut -f1 -d"T"` 
				echo $result 
				;; 
    Questions) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK status|cut -f4 -d":"|cut -f1 -d"S"` 
                echo $result 
                ;; 
    Slow_queries) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK status |cut -f5 -d":"|cut -f1 -d"O"` 
                echo $result 
                ;; 
    Com_select) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_select"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_update) 
		result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_update"|cut -d"|" -f3` 
				echo $result 
				;; 
    Com_rollback) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_rollback"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_insert) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_insert"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_delete) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_delete"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_commit) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_commit"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Bytes_sent) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Bytes_sent" |cut -d"|" -f3` 
                echo $result 
                ;; 
    Bytes_received) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Bytes_received" |cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_begin) 
        result=`mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_begin"|cut -d"|" -f3` 
                echo $result 
                ;; 
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
		echo "Usage:$0(Uptime|Questions|Slow_queries|Com_update|Com_select|Com_rollback|Com_insert| Com_delete|Com_commit|Bytes_sent|Bytes_received|Com_begin|Query|Sleep|Connect|Binlog)" 
			;; 
esac 
