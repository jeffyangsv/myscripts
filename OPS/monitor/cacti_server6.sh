#!/bin/bash
##################################################
#Name:        cacti_server6.sh
#Version:     v1.0
#Create_Date：2016-4-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "部署Cacti监控平台"
##################################################

#快速搭建LAMP平台
#搭建Yum仓库
#安装snmp简单网络管理协议
echo “执行此脚本前要创建数据库cactidb存储配置信息并对其进行用户授权！！！”
read -p " 请输入数据库cactidb授权用户: " Usr
read -p " 请输入数据库cactidb授权用户密码: " Sec
read -p " 请输入Cacti监控主机的ip地址: " IP
PHP=/var/www/html/cacti/include/config.php
#Host=Cacti.$Usr.com
#sed -i '/^HOSTNAME/s/=.*/='$Host''  /etc/sysconfig/network   &>/dev/null
rm -rf /etc/yum.repos.d/*         &>/dev/null
yum-config-manager --add http://192.168.4.254/rhel6 &>/dev/null
sed -i '$agpgcheck=0' /etc/yum.repos.d/192.168.4.254_rhel6.repo &>/dev/null
yum -y install httpd  mysql mysql-server  php php-mysql &>/dev/null
yum -y install firefox
yum -y install rrdtool net-snmp*  &>/dev/null
service httpd restart             &>/dev/null
service mysqld restart            &>/dev/null
chkconfig httpd on                &>/dev/null
chkconfig mysqld on               &>/dev/null
echo "<?php
phpinfo()
?>"  > /var/www/html/index.php
#快速安装Cacti软件包，执行本段脚本，要有数据库cactidb
cd /root/
unzip cacti.zip                    &>/dev/null
cd /root/cacti
tar cf cacti-0.8.7g.tar.gz         &>/dev/null
tar xf cacti-0.8.7g.tar.gz         &>/dev/null
mv cacti-0.8.7g /var/www/html/cacti  
chown  -R apache:apache /var/www/html/cacti/
#存发收集的监控数据 /var/www/html/cacti/rra
#设置cacti服务数据库存储配置信息
sed -i '/^$database/d' $PHP
sed -i '$a$database_type = "mysql"'  $PHP
sed -i '$a$database_default = "cactidb"'  $PHP
sed -i '$a$database_hostname = "localhost"'  $PHP
sed -i '$a$database_username = "'$usr'"' $PHP
sed -i '$a$database_password = "'$Sec'"'  $PHP
sed -i '$a$database_port = "3306"'  $PHP
mysql -u$usr -p$Sec cactidb < /var/www/html/cacticacti.sql
#访问web页面安装cacti
#http://$IP/cacti
#admin 管理员名
#admin 登录初始密码
sed  -i '/^com2sec/s/default/127.0.0.1/' /etc/snmp/snmpd.conf
sed  -i '/^access  notConfigGroup/s/systemview/all/' /etc/snmp/snmpd.conf
sed  -i '/^#view all/s/#view all/view all/' /etc/snmp/snmpd.conf
sed -i '/^;date.timezone/s/;date.timezone/date.timezone/' /etc/php.ini
sed -i '/^date.timezone/s/=.*/=Asia\/Chongqing/' /etc/php.ini

service snmpd restart               &>/dev/null
chkconfig snmpd on                  &>/dev/null
netstat -anptu | grep snmp

#快速安装Cacti软件包插件
cd /root/cacti
tar xf cacti-plugin-0.8.7g-PA-v2.9.tar.gz
mv cacti-plugin-arch/ /var/www/html/cacti/
cd /var/www/html/cacti/
patch -N -p1  < cacti-plugin-arch/cacti-plugin-0.8.7g-PA-v2.9.diff
sed -i '/^url_path/s#/#/cacti/#' $PHP
mysql -u$usr -p$Sec cactidb  < /var/www/html/cacti/cacti-plugin-arch/pa.sql
cd /root/cacti
tar xf monitor-v1.3-1.tgz
tar xf  settings-v0.71-1.tgz 
tar xf  thold-v0.4.9-3.tgz
cp  monitor  /var/www/html/cacti/plugins/
mv  settings  /var/www/html/cacti/plugins/ 
mv  thold  /var/www/html/cacti/plugins/ 

echo "请登录Cacti监控网页完成相关配置"
firefox http://$IP/cacti



