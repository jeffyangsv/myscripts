#!/bin/bash
##################################################
#Name:        host_user_add.sh
#Version:     v1.0
#Create_Date：2016-3-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "服务器上批量添加用户"
##################################################

for IP in `cat /root/all_iplist.txt | awk '{print $2}'`
do  
#   ssh-copy-id root@$ip
    ssh -X root@$IP
    useradd glk888
    echo 123456 | passwd --stdin glk888
    exit
done
