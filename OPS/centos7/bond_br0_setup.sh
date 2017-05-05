#!/bin/bash
##################################################
#Name:        bond_br0_setup.sh
#Version:     v1.0
#Create_Date：2017-1-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Centos7上Bond0设置"
##################################################

IP=172.16.1.100
GATEWAY=172.16.1.2
OLDNAME1=em33
OLDNAME2=em34
ETH0=eth0
ETH1=eth1
#1.网卡设备名修改
if [ -f /etc/sysconfig/network-scripts/ifcfg-$OLDNAME1 ];then
    mv /etc/sysconfig/network-scripts/ifcfg-$OLDNAME1 /etc/sysconfig/network-scripts/ifcfg-$ETH0
fi
if [ -f /etc/sysconfig/network-scripts/ifcfg-$OLDNAME2 ];then
    mv /etc/sysconfig/network-scripts/ifcfg-$OLDNAME2 /etc/sysconfig/network-scripts/ifcfg-$ETH0
fi 
if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH0 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-$ETH0{,.bak}
    echo "TYPE=Ethernet
BOOTPROTO=none
NAME=$ETH0
DEVICE=$ETH0
ONBOOT=yes
MASTER=bond0" > /etc/sysconfig/network-scripts/ifcfg-$ETH0
else
   echo "ifcfg-$ETH0网卡不存在"
fi

if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH1 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-$ETH1{,.bak}
echo "TYPE=Ethernet
BOOTPROTO=none
NAME=$ETH1
DEVICE=$ETH1
ONBOOT=yes
MASTER=bond0" > /etc/sysconfig/network-scripts/ifcfg-$ETH1
else
   echo "ifcfg-$ETH1网卡不存在"
fi

echo "TYPE=Bond
BOOTPROTO=none
PEEDNS=yes
BONDING_MASTER=yes
NAME=bond0
DEVICE=bond0
ONBOOT=yes
BRIDGE=br0" > /etc/sysconfig/network-scripts/ifcfg-bond0
echo "TYPE=Bridge
BOOTPROTO=static
PEEDNS=yes
NAME=br0
DEVICE=br0
ONBOOT=yes
IPADDR=$IP
#NETMASK=255.255.255.0
PREFIX=24  
GATEWAY=$GATEWAY
DNS1=223.5.5.5
USERCTL=no"  > /etc/sysconfig/network-scripts/ifcfg-br0

#2.编辑内核信息
if [ -f etc/sysconfig/grub.bak ];then
    	echo "内核信息已编辑"
else
  mv /etc/sysconfig/grub{,.bak}
  echo 'GRUB_TIMEOUT=5
  GRUB_DEFAULT=saved
  GRUB_DISABLE_SUBMENU=true
  GRUB_TERMINAL_OUTPUT="console"
  GRUB_CMDLINE_LINUX="crashkernel=auto rhgb net.ifnames=0 biosdevname=0 quiet"
  GRUB_DISABLE_RECOVERY="true"'   >  /etc/sysconfig/grub
  grub2-mkconfig -o /boot/grub2/grub.cfg
fi
  
#3.网卡设置成bond1模式
if [ $( grep "ifenslave bond0 eth0 eth1" /etc/rc.local | wc -l) -eq 0 ];then
	echo "ifenslave bond0 eth0 eth1" >> /etc/rc.local
else
	echo "bond1模式已设置"
fi

#4.重启network
systemctl restart network
