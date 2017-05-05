#!/bin/sh
##################################################
#Name:        check_web_diff.sh
#Version:     v1.0
#Create_Date：2016-5-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "验证网站目录下文件是否被篡改"
##################################################

#服务启动时，创建指纹库
find /var/www/html/test/ -type f -name "*" | xargs md5sum > /tmp/checkmd5.db
#取监控目录的文件数目
ls -l /var/www/html/test/*  >  /tmp/site.log
#根据指纹库，对比是否发生变化
#md5sum -c /tmp/checkmd5.db
#过滤发生变化的文件
#md5sum -c /tmp/checkmd5.db |grep -i '失败'
while true 
do
   num=`cat /tmp/site.log | wc -l`
   md5num=`md5sum -c /tmp/checkmd5.db | grep -i '失败' | wc -l`
   filenum=`ls -l /var/www/html/test/* |wc -l`
   if [  $md5num -ne 0 ]; then
      echo "`md5sum -c /tmp/checkmd5.db |grep -i '失败'`"
   fi
   if [ $filenum -ne $num ];then
      echo "/var/www/html/test/  dir is change"
      ls  -l /var/www/html/test/*  >  /tmp/site1.log
      echo  "变化的文件是：`diff  /tmp/site.log /tmp/site1.log  | grep "<\|>" | awk '{print $10}'`"
   fi
   sleep 10
done
