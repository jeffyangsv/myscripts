#!/bin/sh 
source /etc/profile
MYSQL_SOCK="/tmp/mysql.sock"
MYSQL_PWD="d8A7#8z7b"
ARGS=1 
if [ $# -ne "$ARGS" ];then 
    echo "Please input onearguement:" 
fi 
case $1 in 
    Uptime) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK status|cut -f2 -d":"|cut -f1 -d"T"` 
    echo $result 
    ;; 
    Com_update) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_update"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Slow_queries) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK status |cut -f5 -d":"|cut -f1 -d"O"` 
    echo $result 
    ;; 
    Com_select) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_select"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Com_rollback) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_rollback"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Questions) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK status|cut -f4 -d":"|cut -f1 -d"S"` 
    echo $result 
    ;; 
    Com_insert) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_insert"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Com_delete) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_delete"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Com_commit) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_commit"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Bytes_sent) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Bytes_sent"|cut -d"|" -f3` 
    echo $result 
    ;; 
    Bytes_received) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Bytes_received" |cut -d"|" -f3` 
    echo $result 
    ;; 
    Com_begin) 
    result=`mysqladmin -uroot -p${MYSQL_PWD} -S $MYSQL_SOCK extended-status |grep -w "Com_begin"|cut -d"|" -f3` 
    echo $result 
    ;; 
    *) 
    echo"Usage:$0(Uptime|Com_update|Slow_queries|Com_select|Com_rollback|Questions)"
    ;; 
esac 
