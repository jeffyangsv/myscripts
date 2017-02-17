#!/bin/bash
##################################################
#Name:        doceker_enter.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "进入容器Enter containe"
##################################################

CNAME=$1
CPID=$(docker inspect --format "{{.State.Pid}}" $CNAME)
echo "容器${CNAME}的pid是${CPID}"
nsenter --target "$CPID" --uts --ipc --net --pid

