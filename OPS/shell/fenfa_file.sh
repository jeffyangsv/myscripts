#!/bin/bash
##################################################
#Name:        fenfa_file.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "分发文件到服务器"
##################################################

#本脚本适合root用户下运行
read -p "请输入要分发的文件：" FILE
read -p "请输入要路径：" DIR
for i in {100,110,120}
do
scp $FILE 192.168.4.$i:$DIR
done
