#!/bin/bash
##################################################
#Name:        cacti_client6.sh
#Version:     v1.0
#Create_Date：2016-4-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Cacti监控主机客户端安装"
##################################################

read -p " 请输入Cacti监控主机的ip地址: " IP
yum -y install net-snmp* &>/dev/null
sed  -i '/^com2sec/s/default/'$IP'/' /etc/snmp/snmpd.conf &>/dev/null
sed  -i '/^access  notConfigGroup/s/systemview/all/' /etc/snmp/snmpd.conf &>/dev/null
sed  -i '/^#view all/s/#view all/view all/' /etc/snmp/snmpd.conf &>/dev/null
service snmpd restart    &>/dev/null
chkconfig snmpd on       &>/dev/null
netstat -anptu | grep snmp
