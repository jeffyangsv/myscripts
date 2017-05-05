#!/bin/bash
##################################################
#Name:        mysql_kill.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "MySQL中kill掉所有锁表的进程"
##################################################

#mysql -u root -e "show processlist" | grep -i "Locked" >> locked_log.txt
#for line in `cat locked_log.txt | awk '{print $1}'`
#do 
#   echo "kill $line;" >> kill_thread_id.sql
#done

for id in `mysqladmin -uroot -p123456  processlist | grep -i locked | awk '{print $2}'`
#for id in `mysqladmin -uroot -p123456  processlist | grep -i sleep | awk '{print $2}'`
do
   mysqladmin -uroot -p123456  kill ${id}
done


