#!/bin/bash
# get the list service if running in the server
printf '{\n'
printf '\t"data":[\n'
getservice() {
ps axu | grep -v grep | grep $1 &> /dev/null
if [ $? == 0 ];then
if [ $1 != 'sshd' ]; then
printf '\t {\n'
echo '"{#PROCNAME}":' \"$1\" '},'
else
printf '\t {\n'
echo '"{#PROCNAME}":' \"$1\" '}'
fi
fi
}
services="httpd mysqld nginx zabbix_agentd zabbix_server zabbix_proxy sshd"
for srv in $services;do
getservice $srv
done
printf '\t ]\n'
printf '}\n'
