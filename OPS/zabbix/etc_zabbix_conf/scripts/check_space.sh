#!/bin/sh
################################################
# use check space test
# 2016-08-31 by liuzhihao
################################################

NUM1=`df | grep '^/dev/mapper' | awk '{print $4}'`
while true 
do
   NUM2=`df | grep '^/dev/mapper' | awk '{print $4}'`
   chazhi=$[$NUM1-$NUM2]
   echo $chazhi 
if [  $chazhi -ge 10240 ]; then
   echo "磁盘空间变化超过10M"
   break
fi
   sleep 3
done
