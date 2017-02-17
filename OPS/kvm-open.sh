#!/bin/bash
#Date:2016-07-04
#Author：Guolikai(glk73748196@sina.com)
#Description:克隆之后,批量复制虚拟机
NODE=`virsh list --all | awk '{print $2}'`
for i in {1..99}
do
  expect <<EOF
    spawn  clone-vm      &> /dev/null
    expect "number"
    send "$i\r"
  expect eof
EOF
done
#for node in $NODE
#do 
#  virsh deminfo $node              	   #查看虚拟机信息  
#  virsh start $node                	   #开启虚拟机
#  virsh reboot $node               	   #重启虚拟机
#  virsh autostart $node            	   #虚拟机设置成自动开机
#  virsh autostart --disable $node   	   #虚拟机设置成禁用自动开机
#  virsh destroy $node  &> /dev/null         #虚拟机强制关机
#  virsh dumpxml $node > /tmp/{$node}.xml    #虚拟机导出设置
#done
