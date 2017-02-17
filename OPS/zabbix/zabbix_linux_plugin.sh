#!/bin/bash
################################################
#Name:         zabbix_linux_plugin.sh
#Version:      v1.0
#Function:     zabbix plugins
#Create_Date： 2016-8-20
#Author:       GuoLikai(glk73748196@sina.com)
#Description:  "Monitor Linux Service Status"
################################################
tcp_status_fun(){
	TCP_STAT=$1
	#netstat -n | awk '/^tcp/{++state[$NF]} END {for (key in state) print key,state[key]}'  > /tmp/netstat.tmp
	ss -ant | awk 'NR>1 {++s[$1]} END {for (k in s) print k,s[k]}' > /tmp/netstat.tmp
	chown zabbix /tmp/netstat.tmp
	TCP_STAT_VALUE=$(grep "$TCP_STAT" /tmp/netstat.tmp | cut -d ' ' -f2)
	if [ -z $TCP_STAT_VALUE ];then
		TCP_STAT_VALUE=0
	fi
	echo $TCP_STAT_VALUE
}
nginx_status_fun() {
        NGINX_PORT=$1 
        NGINX_COMMAND=$2      
        nginx_active () {
        /usr/bin/curl "http://127.0.0.1:$nginx_port/nginx_status/"  2 /dev/null | grep 'Active' | awk '{print $NF}'
        }   
		nginx_reading () {
        /usr/bin/curl "http://127.0.0.1:$nginx_port/nginx_status/"  2 /dev/null | grep 'Reading' | awk '{print $2}'
        }  
		 nginx_wrting () {
        /usr/bin/curl "http://127.0.0.1:$nginx_port/nginx_status/"  2 /dev/null | grep 'Writing' | awk '{print $4}'
		}
}
main (){
	case $1 in
		tcp_status)
			tcp_status_fun $2;
			;;
		nginx_status)
			nginx_status_fun $2 $3;
			;;
		memcached_status)
			memcached_status_fun $2 $3;
			;;
		redis_status)
			redis_status_fun $2 $3;
			;;
		*)
			echo $"Usage: $0 (tcp_status key | nginx_status key| memcached_status key | redis_status key)"			
		esac
}
main $1 $2 $3

