#!/bin/bash
##################################################
#Name:        discovery_port-pid-cmd.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "自动发现linux下端口、pid、cmd"
##################################################
netstat -tnlp|egrep -i "$1"|awk {'print $4'}|awk -F':' '{if ($NF~/^[0-9]*$/) print $NF}'|sort |uniq  > /root/discoveryport.tmp
for PORT in `cat /root/discoveryport.tmp`
do
  PID=`netstat -tnlp | grep -w $PORT | awk '{print $7}' | awk -F"/" '{print $1}' | uniq`	
  #CMD=`ps aux | awk '{if($2=="'$PID'")print $11}'`
  CMD=`ps aux | awk '{if($2=="'$PID'")print}'| awk '{for(i=11;i<=NF;i++)printf $i "  ";printf"\n"}'`
  echo $PORT $PID $CMD
done

