#!/bin/bash
##################################################
#Name:        fenfa_pub.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "分发公钥到服务器"
##################################################

. /etc/init.d/functions
for ip in `cat all_iplist.txt | awk '{print $2}'`
do
  expect fenfa_sshkey.exp ~/.ssh/id_dsa.pub $ip &>/dev/null
    if [ $? -eq 0 ];then
       action "$ip" /bin/true
    else 
       action "$ip" /bin/false
    fi
done
