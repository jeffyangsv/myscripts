#!/bin/bash
##################################################
#Name:        cobble_auto_install.sh
#Version:     v1.0
#Create_Date：2017-7-21
#Author:      GuoLikai
#Description: "Centos7上Cobbler安装脚本"
##################################################

AppName=cobbler
HOST_IP=$(/usr/sbin/ifconfig eth0 | grep inet | grep -v inet6 | awk -F ' ' '{print $2}')
#DNS=$HOST_IP
DNS=223.5.5.5
Domain_Name=yanxiu.com
HOST_IP_BASE=$(echo ${HOST_IP} | cut -d . -f 1-3)
HOST_SUBNET=${HOST_IP_BASE}.0
SUBNET_MASK=$(/usr/sbin/ifconfig eth0 | grep inet | grep -v inet6  | awk -F ' ' '{print $4}' | head -1)
SUBNET_START=${HOST_IP_BASE}.1
SUBNET_END=${HOST_IP_BASE}.254
GATEWAY=$(route -n | grep UG | awk '{print $2}' | head -1)

fosinit(){
    sed -i "/^SELINUX=/cSELINUX=disabled" /etc/selinux/config
    setenforce 0
    systemctl stop firewalled
    systemctl disable firewalled
    wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel-7.repo
}

finstall(){
    yum install -y  cobbler cobbler-web tftp-server pykickstart dhcp httpd xinetd dnsmasq && yum clean all
    systemctl start  httpd cobblerd rsyncd xinetd
    systemctl enable httpd cobblerd rsyncd xinetd dhcpd 
    cobbler check
}
fremove(){
   tar -cf  ~/cobbler_config.tar.gz /etc/cobbler  &&  rpm -e cobbler-web && rpm -e cobbler && rm -rf /etc/cobbler
}

fconfig(){
    cp /etc/cobbler/settings{,.bak}
    sed -i "/^server/cserver: ${HOST_IP}"                                          /etc/cobbler/settings
    sed -i "/^next_server/cnext_server: ${HOST_IP}"                                /etc/cobbler/settings
    sed -i '/^manage_dhcp/cmanage_dhcp: 1'                                         /etc/cobbler/settings
    sed -i '/[[:space:]]disable/s#yes#no#'                                         /etc/xinetd.d/tftp
    PASSWORD=$(openssl passwd -1 -salt 'suiji' 'admin')
    sed -i "/^default_password_crypted/cdefault_password_crypted: \"${PASSWORD}\"" /etc/cobbler/settings
    sed -n "/^default_password_crypted/p"  /etc/cobbler/settings
    cobbler get-loaders
    #yum -y install debmirror yum-utils fence-agents
    cp /etc/cobbler/dhcp.template{,.bak}
    sed -i "/^subnet 192.168.1.0/s#192.168.1.0#${HOST_SUBNET}#"                    /etc/cobbler/dhcp.template
    sed -i "/[[:space:]]option routers/s#192.168.1.5#${GATEWAY}#"                  /etc/cobbler/dhcp.template
    sed -i "/[[:space:]]option subnet-mask/s#255.255.255.0#${SUBNET_MASK}#"        /etc/cobbler/dhcp.template
    sed -i "/[[:space:]]option domain-name-servers/s#192.168.1.1#${DNS}#"          /etc/cobbler/dhcp.template
    sed -i "/[[:space:]]range dynamic-bootp/s#192.168.1.100 192.168.1.254#${SUBNET_START} ${SUBNET_END}#" /etc/cobbler/dhcp.template
    sed -i "/cobbler.github.io/s#cobbler.github.io#${Domain_Name}#" /etc/cobbler/pxe/pxedefault.template
    cobbler sync 
    cat /etc/dhcp/dhcpd.conf
    systemctl restart dhcpd && systemctl restart cobblerd
    cobbler check
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "osinit"    ) fosinit;;
    "install"   ) finstall;;
    "remove"    ) fremove;;
    "config"    ) fconfig;;
    *           )
    echo "$ScriptFile osinit               系统 $AppName"
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile config               配置 $AppName"
    ;;
esac
