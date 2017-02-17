#!/bin/bash
##################################################
#Name:        bond_br0_setup.sh
#Version:     v1.0
#Create_Date：2017-1-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Centos7上Bond0设置"
##################################################
echo "TYPE=Ethernet
BOOTPROTO=none
NAME=em1
DEVICE=em1
ONBOOT=yes
MASTER=bond0" > /etc/sysconfig/network-scripts/ifcfg-em1
echo "TYPE=Ethernet
BOOTPROTO=none
NAME=em2
DEVICE=em2
ONBOOT=yes
MASTER=bond0" > /etc/sysconfig/network-scripts/ifcfg-em2
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
IPADDR=172.16.1.100
NETMASK=255.255.255.0
GATEWAY=172.16.1.2
DNS1=223.5.5.5
USERCTL=no"  > /etc/sysconfig/network-scripts/ifcfg-br0

