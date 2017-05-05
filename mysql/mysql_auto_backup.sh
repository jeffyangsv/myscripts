#!/bin/bash
##################################################
#Name:        mysql_auto_backup.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Mysql_Auto_Backup"
##################################################

Date=`date +%Y%m%d`
mysqldump --all-databases -uroot -p123456 > /root/DataBackup/localhost/mysql/mysqlall${Date}.sql

