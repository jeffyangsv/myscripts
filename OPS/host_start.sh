#!/bin/bash
##################################################
#Name:        start_host.sh
#Version:     v1.0
#Create_Date：2016-7-1
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "唤醒未运行的主机"
##################################################

for IP in 172.40.55.{1..254}
do
  ping -c2 $IP &> /dev/null 
  if [ $? -eq 0 ];then
	echo "$IP is Up"
	if [ $IP in `awk '{print $1}'` ]
	arp -n  $IP |  awk '$3~HWaddress {getline;print $1"\t",$3}'  >>  /root/macup.txt
#	expect <<EOF
#	spawn ssh -X  root@$IP  "/sbin/shutdown -h now" 
#	expect "password:"
#	send "tedu.cn\r"
#EOF	
	fi
    else
 	echo "$IP is down"
	mac=`sed -n  "/$IP/p" /root/macup.txt | awk '{print $2}'`
	ether-wake -i br0  $mac
    fi
done
