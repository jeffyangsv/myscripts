#!/bin/bash
##################################################
#Name:        fenfa_file_host.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "分发文件到服务器"
##################################################

. /etc/init.d/functions
File="$1"      #传参文件
Removedir="$2" #远程服务器目录
if [ $# -ne 2 ];then    #若参数不满足2个，将出现如下错误信息
#: $#获取当前shell命令行中参数
#：ne 不等于
#：$0 当前shell命令行中首个参数
   echo "Usage:$0 argv1 argv2" 
   echo "You must input two argvs"
   exit
fi
for  ip in `cat /home/glk888/all_iplist.txt`   #调用cat命令结果
do
   scp   $File glk888@$ip:~  &>/dev/null &&\
   ssh  -t glk888@$ip  sudo /bin/cp -rfp  $File  $Removedir   &>/dev/null
#采用ssh key实现免密码验证登录
#通过ssh通道执行sudo命令将文件拷贝到普通用户没有权限的目录
# $?:上次执行命令的结果
# eq 等于
if [ $? -eq 0 ];then
   echo "$ip is success!"
else 
   echo "$ip is failure!"   
fi
done








