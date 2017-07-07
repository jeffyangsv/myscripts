#!/bin/bash
#--------------------------------------------------
# Name:        setup_network_info.sh
# Version:     v1.0
# Create_Date：2017-4-1
# Author:      GuoLikai(glk73748196@sina.com)
# Description: "centos7修改主机网卡名与IP脚本"
#--------------------------------------------------

OUTNET=192.168.7
INNET=10.10.10
OLDIP=${OUTNET}.100
NETMASK=255.255.255.0
GATEWAY=${OUTNET}.2
ETH0=eth0


#编辑内核信息
fgrub()
{
    if [ -f /etc/default/grub.bak ];then
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
        echo "内核信息已修改，需重启服务器"
    fi
}

#修改主机网卡名
feth0(){
    if [ -f /etc/sysconfig/network-scripts/ifcfg-ens33 ];then 
        /usr/bin/cp /etc/sysconfig/network-scripts/ifcfg-ens33{,.bak}
        mv /etc/sysconfig/network-scripts/ifcfg-ens33 /etc/sysconfig/network-scripts/ifcfg-$ETH0
    fi
    if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH0 ];then 
        /usr/bin/cp /etc/sysconfig/network-scripts/ifcfg-$ETH0{,.bak}
        echo "TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=${ETH0}
DEVICE=${ETH0}
ONBOOT=yes
IPADDR=${OLDIP}
NETMASK=${NETMASK}
GATEWAY=${GATEWAY}
DNS1=223.5.5.5"  > /etc/sysconfig/network-scripts/ifcfg-$ETH0 
    else
        echo "ifcfg-$ETH0网卡不存在"
    fi
}

#修改主机网卡ip
fsetip ()
{
    echo "$#"
    IPHOST=$1
    if [ $# -eq 1 ];then
        sed -i "/^IPADDR/cIPADDR=${OUTNET}.$IPHOST" /etc/sysconfig/network-scripts/ifcfg-${ETH0}
        #sed -i "/^IPADDR/cIPADDR=${INNET}.$IPHOST" /etc/sysconfig/network-scripts/ifcfg-eth1
        sed -i  '/^IPV6INIT/cIPV6INIT=no' /etc/sysconfig/network-scripts/ifcfg-${ETH0}
        #sed -i  '/^IPV6INIT/cIPV6INIT=no' /etc/sysconfig/network-scripts/ifcfg-eth1
        echo "修改主机网卡ip成功,请手动重启网卡"
        #/etc/init.d/network restart
    else
        echo "USAGE: $0脚本后需要跟参数: setip IP_HOST"
        exit 1
    fi
}

fmodname (){
    if [ -f /etc/sysconfig/network-scripts/ifcfg-ens33.bak ];then
        echo "etho网卡已被修改"
    else
        fgrub && feth0
        exit 1
    fi
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "eth0"    ) feth0;;
    "grub"    ) fgrub;;
    "modname" ) fmodname;;
    "setip"   ) fsetip $2;;
    *         )
    echo "$ScriptFile eth0              配置网卡$ETH0"
    echo "$ScriptFile grub              修改内核信息"
    echo "$ScriptFile modname           修改网卡信息"
    echo "$ScriptFile setip IP_HOST     修改IP地址"
    ;;
esac
