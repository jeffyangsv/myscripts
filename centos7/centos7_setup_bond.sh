#!/bin/bash
##################################################
#Name:        centos7_setup_bond.sh
#Version:     v1.0
#Create_Date：2017-7-20
#Author:      GuoLikai
#Description: "Centos7上模式Bond1链路接口设置"
##################################################

#BOND_IP=10.10.20.1
BOND_IP_BASE=10.10.20
BOND_NETMASK=255.255.254.0
BOND_GATEWAY=${BOND_IP_BASE}.254
#BACKUP_IP=172.18.9.201
BACKUP_IP_BASE=172.18.9
BACKUP_NETMASK=255.255.255.0
BACKUP_GATEWAY=${BACKUP_IP_BASE}.254

ETH0=eth0
ETH1=eth1  
ETH2=eth2  
ETH3=eth3


#修改网卡配置网卡
feth0(){
    if [ -f /etc/sysconfig/network-scripts/ifcfg-em1 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-em1{,.bak}
        mv /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-$ETH0
    fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH0 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-$ETH0{,.bak}
        echo "TYPE=Ethernet
DEVICE=$ETH0
NAME=$ETH0
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0 
SLAVE=yes" > /etc/sysconfig/network-scripts/ifcfg-$ETH0 
    else
       echo "ifcfg-$ETH0网卡不存在"
    fi
}

feth1(){
    if [ -f /etc/sysconfig/network-scripts/ifcfg-em2 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-em2{,.bak}
        mv /etc/sysconfig/network-scripts/ifcfg-em2 /etc/sysconfig/network-scripts/ifcfg-$ETH1
    fi
    
    if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH1 ];then 
        cp  /etc/sysconfig/network-scripts/ifcfg-$ETH1{,.bak} 
        echo "TYPE=Ethernet
NAME=$ETH1
DEVICE=$ETH1
BOOTPROTO=none
ONBOOT=yes
MASTER=bond0
SLAVE=yes" > /etc/sysconfig/network-scripts/ifcfg-$ETH1 
else
   echo "ifcfg-$ETH1网卡不存在"
fi
}

#修改bond配置网卡
fbond0()
{   
    if [ $# -eq 1 ];then
	    BOND_IP=$1
    else
        echo "USAGE: $0 bond0 ${BOND_IP_BASE}.HOST"
        exit 1   
	fi
    
    if [ -f /etc/sysconfig/network-scripts/ifcfg-bond0 ];then 
        echo "bond0已设置"
    else	
	    echo "DEVICE=bond0
NAME=bond0
BOOTPROTO=static
BONDING_MASTER=yes
IPADDR=$BOND_IP
NETMASK=$BOND_NETMASK
GATEWAY=$BOND_GATEWAY
DNS1=202.106.0.20
DNS2=223.5.5.5
ONBOOT=yes
TYPE=Bond
BONDING_OPTS=mode=active-backup" > /etc/sysconfig/network-scripts/ifcfg-bond0
    fi
} 

feth2(){
    if [ $# -eq 1 ];then
	    BACKUP_IP=$1
    else
        echo "USAGE: $0 eth2 ${BACKUP_IP_BASE}.HOST"
        exit 2    
	fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-em3 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-em3{,.bak}
        mv /etc/sysconfig/network-scripts/ifcfg-em3 /etc/sysconfig/network-scripts/ifcfg-$ETH2
        mv /etc/sysconfig/network-scripts/ifcfg-em4 /etc/sysconfig/network-scripts/ifcfg-em4.bak
    fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH2 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-$ETH2{,.bak} 
    echo "TYPE=Ethernet
BOOTPROTO=static
IPV6_FAILURE_FATAL=no
NAME=$ETH2
DEVICE=$ETH2
ONBOOT=yes
IPADDR=$BACKUP_IP
NETMASK=$BACKUP_NETMASK" > /etc/sysconfig/network-scripts/ifcfg-$ETH2  
    else
        echo "ifcfg-$ETH2网卡不存在"
    fi
}

#编辑内核信息
fgrub()
{
    if [ -f /etc/sysconfig/grub.bak ];then
        echo "内核信息已编辑"
    else
        mv /etc/default/grub{,.bak}
        echo 'GRUB_TIMEOUT=5
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto net.ifnames=0 biosdevname=0 rhgb quiet"
GRUB_DISABLE_RECOVERY="true"'   >  /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
}
#设置bond
fsetbond(){
    if [ $# -eq 1 ];then
        BIND_IP=$1
    else
        echo "USAGE: $0 setbond ${BOND_IP_BASE}.HOST"
        exit 3    
	fi
    if [ $( grep "ifemlave bond0 eth0 eth1" /etc/rc.local | wc -l) -eq 0 ];then
        echo "ifemlave bond0 eth0 eth1" >> /etc/rc.local
        modprobe bonding
        fgrub && fbond0 $BIND_IP && feth0 && feth1 
        echo "bond已设置,需重启服务器，请输入'reboot'" 
    else
        echo "bond模式已设置"
    fi
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "grub"   ) fgrub;;
    "eth0"   ) feth0;;
    "eth1"   ) feth1;;
    "eth2"   ) feth2  $2;;
    "bond0"  ) fbond0 $2;;
    "setbond" ) fsetbond $2;;
     * )
    echo "$ScriptFile grub                  编辑内核信息"
    echo "$ScriptFile eth0                  配置网卡$ETH0"
    echo "$ScriptFile eth1                  配置网卡$ETH1"
    echo "$ScriptFile eth2    backup_ip     备份网卡$ETH2"
    echo "$ScriptFile bond0   bond_ip       配置网卡bond0"
    echo "$ScriptFile setbond bond_ip       设置bond"
    ;;
esac
