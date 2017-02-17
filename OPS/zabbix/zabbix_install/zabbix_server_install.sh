#!/bin/bash
################################################
#Name:         zabbix_server_install.sh
#Version:      v1.0
#Create_Date： 2016-8-20
#Author:       GuoLikai(glk73748196@sina.com)
#Description:  部署zabbix3.0.4版本软件包
################################################

PASSWD=123456     #数据库用户root密码
User=zabbix       #数据库zabbixdb授权用户
Sec=zabbix        #数据库zabbixdb授权用户密码
IP=172.16.1.100  #zabbix监控服务器ip地址
NAME='hostname'   #本机监控主机名

#关闭防火墙及禁用selinux
systemctl disable iptables       &>/dev/null
systemctl disable firewalld      &>/dev/null
systemctl stop firewalld.service &>/dev/null
systemctl stop iptables.service  &>/dev/null
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
#构建LAMP平台及zabbix相关依赖包
yum -y install httpd mariadb-server mariadb* php php-mysql php-gd   php-xml  gcc              &>/dev/null
yum -y install curl curl-devel php-gd net-snmp  net-snmp-devel  openssl-devel libcurl-devel   &>/dev/null
yum -y install OpenIPMI-libs  OpenIPMI-modalias php-ldap php-pgsql  postgresql-libs unixODBC vlgothic-p-fonts  &>/dev/null
#配置MariaDB
systemctl start mariadb.service  &>/dev/null
systemctl enable mariadb.service &>/dev/null
yum -y install expect            &>/dev/null
expect <<EOF
spawn mysqladmin -u root -p password "$PASSWD"  
expect  "Enter password:" 
send "\r"
expect eof
EOF
mysql -uroot -p${PASSWD} -e "create database zabbix character set utf8 "                     &>/dev/null
mysql -uroot -p${PASSWD} -e "grant all on zabbix.* to $User@localhost identified by  '$Sec' "   &>/dev/null
mysql -uroot -p${PASSWD} -e "flush privileges"   &>/dev/null
#部署zabbix3.0服务
useradd zabbix -s /sbin/nologin                  &>/dev/null
cd /root/rpms/zabbix304/
rpm -ivh iksemel-1.4-6.el7.x86_64.rpm
rpm -ivh fping-3.10-4.el7.x86_64.rpm
rpm -ivh php-bcmath-5.4.16-36.el7_1.x86_64.rpm
rpm -ivh php-common-5.4.16-36.el7_1.x86_64.rpm
rpm -ivh php-mbstring-5.4.16-36.el7_1.x86_64.rpm
yum -y install  zabbix-*.rpm                 &>/dev/null
zcat /usr/share/doc/zabbix-server-mysql-3.0.4/create.sql.gz | mysql -u${User} -p${Sec} zabbix
sed -i "s@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g" /etc/httpd/conf.d/zabbix.conf
cp /root/rpms/zabbix304/simkai.ttf  /usr/share/zabbix/fonts/
sed -i "s#graphfont#simkai#g" /usr/share/zabbix/include/defines.inc.php
sed -i "/^function getLocales/{n;;n;n;n;n;s/false/true/}"  /usr/share/zabbix/include/locales.inc.php

#修改zabbix服务器配置文件
sed -i "/^DBName/cDBName=zabbix"           /etc/zabbix/zabbix_server.conf          #设置zabbix数据库名称
sed -i "/^DBUser/cDBUser=$User"            /etc/zabbix/zabbix_server.conf          #设置zabbix数据库账户
sed -i "/^# DBPassword/cDBPassword=$Sec"   /etc/zabbix/zabbix_server.conf          #设置zabbix数据库密码
chown -R zabbix:zabbix /var/log/zabbix
chown -R zabbix:zabbix /var/run/zabbix
chmod -R 775 /var/log/zabbix/
chmod -R 775 /var/run/zabbix/
systemctl restart httpd
systemctl restart zabbix-server
systemctl enable  zabbix-server
systemctl enable  httpd
echo "查看zabbix服务端口:" && netstat -anptu | grep zabbix       


#rhel7客户端安装：
sed -i "/^Server=/cServer=127.0.0.1,$IP"    /etc/zabbix/zabbix_agentd.conf        #被动模式zabbix服务器地址  
sed -i "/^ServerActive/cServerActive=$IP"   /etc/zabbix/zabbix_agentd.conf        #被动模式zabbix服务器地址
sed -i "/^Hostname/cHostname=$NAME"  /etc/zabbix/zabbix_agentd.conf               #本机监控主机名
systemctl restart zabbix-agent
systemctl enable  zabbix-agent
#rhel6客户端安装：
#rpm -ivh zabbix-agent-3.0.4-1.el6.x86_64.rpm 
#rpm -ivh zabbix-get-3.0.4-1.el6.x86_64.rpm 
#sed -i "/^Server/cServer='$IP'"               /etc/zabbix/zabbix_agentd.conf     #被动模式zabbix服务器地址
#sed -i "/^ServerActive/cServerActive='$IP'"   /etc/zabbix/zabbix_agentd.conf     #主动模式zabbix服务器地址
#sed -i "/^Hostname/cHostname='$NAME'"  /etc/zabbix/zabbix_agentd.conf     #本机监控主机名
#service zabbix-agent start
#chkconfig zabbix-agent on

