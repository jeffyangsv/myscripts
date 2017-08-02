#!/bin/sh
#-------------------------------------------------
#Name:        centos6_setup-bond-R710.sh
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

#fem1(){
#if [ -f /etc/sysconfig/network-scripts/ifcfg-em1 ];then
#	cp /etc/sysconfig/network-scripts/ifcfg-em1 /etc/sysconfig/network-scripts/ifcfg-em1.bak
#    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em1
#DEVICE=em1
#NAME=em1
#ONBOOT=yes
#BOOTPROTO=none
#MASTER=bond0
#SLAVE=yes
#EOF
#else
#    echo "ifcfg-em1网卡不存在"
#fi
#}
fem2(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-em2 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-em2 /etc/sysconfig/network-scripts/ifcfg-em2.bak
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em2
DEVICE=em2
NAME=em2
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
EOF
else
    echo "ifcfg-em2网卡不存在"
fi
}

fem3(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-em3 ];then
    cp /etc/sysconfig/network-scripts/ifcfg-em3 /etc/sysconfig/network-scripts/ifcfg-em3.bak
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em3
DEVICE=em3
NAME=em3
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
EOF
else
    echo "ifcfg-em3网卡不存在"
fi
}

fem4(){
    if [ $# -eq 1 ];then
        BACKUP_IP=$1
        BACKUP_IP_Base=$(echo ${BACKUP_IP} | cut -d . -f  1-3)
        BACKUP_GATEWAY=${BOND_IP_Base}.${GATEWAY_NUM}
    else
        echo "USAGE: $0 em4 ${BACKUP_IP_BASE}.HOST"
        exit 2    
    fi

    if [ -f /etc/sysconfig/network-scripts/ifcfg-em4 ];then 
        cp /etc/sysconfig/network-scripts/ifcfg-em4{,.bak} 
    cat << EOF > /etc/sysconfig/network-scripts/ifcfg-em4
TYPE=Ethernet
BOOTPROTO=static
IPV6_FAILURE_FATAL=no
NAME=em4
DEVICE=em4
ONBOOT=yes
IPADDR=$BACKUP_IP
NETMASK=$BACKUP_NETMASK
EOF
    else
        echo "ifcfg-em3网卡不存在"
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

fsetbond1(){
cat << EOF >> /etc/modprobe.d/dist.conf
alias bond0 bonding
options bond0 miimon=100 mode=1
EOF

if [ $# -eq 1 ];then
        BIND_IP=$1
    else
        echo "USAGE: $0 setbond ${BOND_IP_BASE}.HOST"
        exit 3    
fi
if [ $( grep "ifenslave bond0 em2 em3" /etc/rc.local | wc -l) -eq 0 ];then
    echo "ifenslave bond0 em2 em3" >> /etc/rc.local
    modprobe bonding
    fem2 && fem3  && fbond0 $BIND_IP
    echo "bond已设置,需重启network服务" 
else
    echo "bond模式已设置"
fi
}


fsetbond4(){
cat << EOF >> /etc/modprobe.d/dist.conf
alias bond0 bonding
options bond0 miimon=100 mode=4
EOF

if [ $# -eq 1 ];then
        BIND_IP=$1
    else
        echo "USAGE: $0 setbond ${BOND_IP_BASE}.HOST"
        exit 3    
fi
if [ $( grep "ifenslave bond0 em2 em3" /etc/rc.local | wc -l) -eq 0 ];then
    echo "ifenslave bond0 em2 em3" >> /etc/rc.local
    modprobe bonding
    fem2 && fem3  && fbond0 $BIND_IP
    echo "bond已设置,需重启network服务" 
else
    echo "bond模式已设置"
fi
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "em2"     ) fem2;;
    "em3"     ) fem3;;
    "em4"     ) fem4     $2;;
    "bond0"   ) fbond0   $2;;
    "setbond" ) fsetbond $2;;
     * )
    echo "$ScriptFile em2                    配置网卡em2"
    echo "$ScriptFile em3                    配置网卡em3"
    echo "$ScriptFile em4      backup_ip     备份网卡em4"
    echo "$ScriptFile bond0    bond_ip       配置网卡bond0"
    echo "$ScriptFile setbond1 bond_ip       设置bond1"
    echo "$ScriptFile setbond4 bond_ip       设置bond4"
    ;;
esac
