#!/bin/bash
##################################################
#Name:        check_web_alive.sh
#Version:     v1.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "检查网站是否Alive"
##################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# define url
#WEB_URL=("http://www.example.com" "http://www1.example.com" "http://www2.example.com")
WEB_URL=("http://192.168.4.254" "http://172.40.55.170")

# check network
NET_ALIVE=$(ping -c 5 '172.40.55.170'  | grep -i 'received'|awk 'BEGIN {FS=","} {print $2}'|awk '{print $1}')

if [ $NET_ALIVE == 0 ]; then
    echo "Network is not active,please check your network configuration!"
    exit 0
fi
# check url
for((i=0; i!=${#WEB_URL[@]}; ++i))
{
  ALIVE=$(curl -o /dev/null -s -m 10 -connect-timeout 10 -w %{http_code} ${WEB_URL[i]} |grep "000000")
  if [ "$ALIVE" == "000000" ]; then
    echo "'${WEB_URL[i]}' can not be open,please check!" | mail -s "Website Notification to $
{WEB_URL[i]}" root@localhost
    echo "failed"
  else
    echo "'${WEB_URL[i]}' is OK!"
  fi
}
