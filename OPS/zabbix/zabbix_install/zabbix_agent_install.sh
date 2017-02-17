#!/bin/bash
################################################
#Name:         zabbix_agent_install.sh
#Version:      v1.0
#Create_Date： 2016-8-20
#Author:       GuoLikai(glk73748196@sina.com)
#Description： zabbix一键安装脚本
#Note：因服务器较多，故在服务端搭建一个可wget软件中心，wget地址可自定义
#Useing: 在客户端直接使用命令安装即可 curl ServerIP/script/install_zabbix_agentd.sh | sh
#下载源码包： wget -O zabbix-3.2.3.tar.gz  https://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/3.2.3/zabbix-3.2.3.tar.gz/download
################################################

ServerIP=172.16.1.100    #zabbix_server服务端IP
Version=zabbix-3.2.3      #zabbix版本
BASEDIR=/usr/local/zabbix #zabbix安装目录
wget='wget -N -P /tmp http://$ServerIP/download/$Version.tar.gz'

## 1、开放防火墙端口
iptables -I INPUT -p tcp -m multiport --dport 10050:10051 -j ACCEPT
service iptables save
service iptables restart
groupadd zabbix
useradd zabbix -g zabbix
ln -s $BASEDIR/sbin/* /usr/local/sbin/
ln -s $BASEDIR/bin/* /usr/local/bin/

## 2、zabbix安装
yum install -y gcc make autoconf gcc net-snmp-devel curl curl-devel mysql-devel
if [ ! -f /tmp/$Version.tar.gz ]
then
$wget
fi

tar zxvf /tmp/$Version.tar.gz -C /tmp
cd /tmp/$Version
./configure --prefix=$BASEDIR --enable-agent --with-net-snmp --with-libcurl
make && make install

## 3、配置zabbix_agentd.conf
sed -i 's:# PidFile=/tmp/zabbix_agentd.pid:LogFile=$BASEDIR/zabbix_agentd.pid:g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's#LogFile=.*$#LogFile=$BASEDIR/log/zabbix_agentd.log#g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's/^Server=127.0.0.1/Server=$ServerIP/g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's/^ServerActive=127.0.0.1/ServerActive=$ServerIP/g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's/# EnableRemoteCommands=0/EnableRemoteCommands=0/g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's/# LogRemoteCommands=0/LogRemoteCommands=0/g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's:# Include=/usr/local/etc/zabbix_agentd.conf.d/*.conf:Include=$BASEDIR/etc/zabbix_agentd.conf.d/*.conf:g' $BASEDIR/etc/zabbix_agentd.conf
sed -i 's/# UnsafeUserParameters=0/UnsafeUserParameters=1/g' $BASEDIR/etc/zabbix_agentd.conf

## 4、开机启动项
cp /tmp/$Version/misc/init.d/fedora/core/zabbix_agentd /etc/rc.d/init.d/zabbix_agentd
sed -i "s:BASEDIR=/usr/local:BASEDIR=$BASEDIR:g" /etc/rc.d/init.d/zabbix_agentd
chmod +x /etc/rc.d/init.d/zabbix_agentd
chkconfig zabbix_agentd on
killall zabbix_agentd
/etc/init.d/zabbix_agentd restart
