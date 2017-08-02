#!/bin/sh
#-------------------------------------------------
#Name:        centos6_setup-bond-R720.sh
#Version:     v1.0
#Create_Date：2017-7-30
#Author:      GuoLikai
#Description: "Centos6绑定双网卡bond1模式"
#-------------------------------------------------

BOND_IP_BASE=10.10.10
BOND_NETMASK=255.255.254.0
GATEWAY_NUM=254
#BOND_GATEWAY=${BOND_IP_BASE}.${GATEWAY_NUM}
BACKUP_IP_BASE=172.18.9
BACKUP_NETMASK=255.255.254.0
#BACKUP_GATEWAY=${BACKUP_IP_BASE}.${GATEWAY_NUM}


feth0(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-em1 ];then 
    mv /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-eth0
fi
if [ -f /etc/sysconfig/network-scripts/ifcfg-eth0 ];then
	cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.bak
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
EOF
else
    echo "ifcfg-eth1网卡不存在"
fi
}

feth1(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-em2 ];then 
    mv /etc/sysconfig/network-scripts/ifcfg-em2 /etc/sysconfig/network-scripts/ifcfg-eth1
fi

if [ -f /etc/sysconfig/network-scripts/ifcfg-eth1 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-eth1.bak
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
DEVICE=eth1
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
EOF
else
    echo "ifcfg-eth2网卡不存在"
fi
}

feth2(){
    if [ $# -eq 1 ];then
        BACKUP_IP=$1
        BACKUP_IP_Base=$(echo ${BACKUP_IP} | cut -d . -f  1-3)
        BACKUP_GATEWAY=${BOND_IP_Base}.${GATEWAY_NUM}
    else
        echo "USAGE: $0 eth2 ${BACKUP_IP_BASE}.HOST"
        exit 2    
    fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-em3 ];then 
        mv /etc/sysconfig/network-scripts/ifcfg-em3 /etc/sysconfig/network-scripts/ifcfg-eth2
        mv /etc/sysconfig/network-scripts/ifcfg-em4 /etc/sysconfig/network-scripts/ifcfg-em4.bak
    fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-eth2 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-eth2{,.bak} 
        cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth2
TYPE=Ethernet
BOOTPROTO=static
IPV6_FAILURE_FATAL=no
NAME=eth2
DEVICE=eth2
ONBOOT=yes
IPADDR=$BACKUP_IP
NETMASK=$BACKUP_NETMASK
EOF
    else
        echo "ifcfg-eth2网卡不存在"
fi

}


fbond0(){
if [ $# -eq 1 ];then
    BOND_IP=$1
    BOND_IP_Base=$(echo ${BOND_IP} | cut -d . -f  1-3)
    BOND_GATEWAY=${BOND_IP_Base}.${GATEWAY_NUM}
else
    echo "USAGE: $0 bond0 ${BOND_IP_BASE}.HOST"
    exit 1   
fi
    
if [ -f /etc/sysconfig/network-scripts/ifcfg-bond0 ];then 
    echo "bond0已设置"
else
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
DEVICE=bond0                
BOOTPROTO=static 
IPADDR=$BOND_IP
NETMASK=$BOND_NETMASK
GATEWAY=$BOND_GATEWAY
DNS1=202.106.0.20
DNS2=223.5.5.5
ONBOOT=yes
TYPE=Ethernet
EOF
fi
}

fsetbond(){
cat << EOF >> /etc/modprobe.d/dist.conf
alias bond0 bonding
options bond0 miimon=100 mode=0
EOF

if [ $# -eq 1 ];then
        BIND_IP=$1
    else
        echo "USAGE: $0 setbond ${BOND_IP_BASE}.HOST"
        exit 3    
fi
if [ $( grep "ifenslave bond0 eth0 eth1" /etc/rc.local | wc -l) -eq 0 ];then
    echo "ifenslave bond0 eth0 eth1" >> /etc/rc.local
    modprobe bonding
    feth0 && feth1  && fbond0 $BIND_IP
    echo "bond已设置,需重启network服务" 
else
    echo "bond模式已设置"
fi
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
#    "grub"   ) fgrub;;
    "eth0"   ) feth0;;
    "eth1"   ) feth1;;
    "eth2"   ) feth2  $2;;
    "bond0"  ) fbond0 $2;;
    "setbond" ) fsetbond $2;;
     * )
#   echo "$ScriptFile grub                  编辑内核信息"
    echo "$ScriptFile eth0                  配置网卡$ETH0"
    echo "$ScriptFile eth1                  配置网卡$ETH1"
    echo "$ScriptFile eth2    backup_ip     备份网卡$ETH2"
    echo "$ScriptFile bond0   bond_ip       配置网卡bond0"
    echo "$ScriptFile setbond bond_ip       设置bond"
    ;;
esac
