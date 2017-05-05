#!/bin/bash
##################################################
#Name:        zabbix_server_v2.sh
#Version:     v2.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Linux服务器部署zabbix软件包"
##################################################


PASSWD=123456   #数据库用户root密码
User=zabbix     #数据库zabbixdb授权用户
Sec=123456      #数据库zabbixdb授权用户密码
IP=192.168.4.90 #zabbixdb监控服务器ip地址
NAME=server     #zabbixdb监控服务器主机名
DIR=/root       #zabbixdb软件包存放路径
USR=/usr/local/zabbix/etc #zabbix服务器配置文件目录
CONF=zabbix_agentd.conf
Conf=zabbix_server.conf 

#yum -y install httpd mariadb-server mariadb*    php  php-mysql  &>/dev/null #rhel7上操作
yum -y install httpd  mysql*  php*  &>/dev/null
yum -y install rrdtool net-snmp*  gcc gcc+     &>/dev/null
yum -y install curl-devel per-DBI php-gd php-xm*  php-bcmath php-mbstring   &>/dev/null
echo "<?php
#phpinfo()
#?>"  > /var/www/html/index.php
service mysqld restart   &>/dev/null
chkconfig mysqld on      &>/dev/null
yum -y install expect
expect <<EOF
spawn mysqladmin -u root -p password "$PASSWD"  
expect  "Enter password:" 
send "\r"
expect eof
EOF
mysql -uroot -p${PASSWD} -e "create database zabbixdb "                 &>/dev/null
mysql -uroot -p${PASSWD} -e "grant all on zabbixdb.* to $User@'localhost' identified by  '$Sec' "   &>/dev/null
mysql -uroot -p${PASSWD} -e "grant all on zabbixdb.* to $User@'%' identified by  '$Sec' "   &>/dev/null

useradd zabbix                         &>/dev/null
unzip -d  $DIR  $DIR/zabbix.zip         &>/dev/null
cd $DIR/zabbix/
tar xf zabbix-2.2.1.tar.gz             &>/dev/null
cd $DIR/zabbix/zabbix-2.2.1/
./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql=/usr/bin/mysql_config  --with-net-snmp --with-libcurl --enable-proxy             &>/dev/null
make                                   &>/dev/null
make install                           &>/dev/null  
cp -rfp  $DIR/zabbix/zabbix-2.2.1/frontends/php /var/www/html/zabbix
cd   $DIR/zabbix
rpm -ivh --nodeps  php-mbstring-5.3.3-22.el6.x86_64.rpm    &>/dev/null
rpm -ivh --nodeps  php-bcmath-5.3.3-22.el6.x86_64.rpm      &>/dev/null    

sed -i '/^post_max_size/cpost_max_size = 32M'       /etc/php.ini
sed -i '/^max_execution_time/cmax_execution_time = 300'  /etc/php.ini
sed -i '/max_input_time/cmax_input_time = 300'       /etc/php.ini
sed -i '/^;date.timezone/cdate.timezone = Asia/Shanghai' /etc/php.ini
sed -i '/^;mbstring.func_overload/cmbstring.func_overload  = 2' /etc/php.ini

mysql -u${User} -p${Sec} zabbixdb      < $DIR/zabbix/zabbix-2.2.1/database/mysql/schema.sql   &>/dev/null
mysql -u${User} -p${Sec} zabbixdb      < $DIR/zabbix/zabbix-2.2.1/database/mysql/images.sql   &>/dev/null
mysql -u${User} -p${Sec} zabbixdb      < $DIR/zabbix/zabbix-2.2.1/database/mysql/data.sql     &>/dev/null

chown -R apache:apache /var/www/html/zabbix  &>/dev/null

/etc/init.d/mysqld restart            &>/dev/null
chkconfig mysqld  on                  &>/dev/null

#修改zabbix服务器配置文件，起服务
cd $DIR/zabbix/zabbix-2.2.1/misc/init.d/fedora/core  &>/dev/null
cp zabbix_server /etc/init.d/         &>/dev/null
chmod +x /etc/init.d/zabbix_server    &>/dev/null  
cd /root 
#chkconfig --add zabbix_server
#chkconfig  --list zabbix_server ##查看是否开自启
mkdir /var/log/zabbix                 &>/dev/null
chown -R zabbix:zabbix /var/log/zabbix  &>/dev/null
sed -i '22s/local.*/local\/zabbix/'  /etc/init.d/zabbix_server #修改zabbix服务器配置文件
sed -i '/^DBName/cDBName=zabbixdb' $USR/$Conf               #设置zabbix数据库名称
sed -i '/^DBUser/cDBUser='$User''  $USR/$Conf               #设置zabbix数据库账户
sed -i '/^# DBPassword/cDBPassword='$Sec'' $USR/$Conf       #设置zabbix数据库密码
sed -i '/^LogFile/cLogFile=\/var\/log\/zabbix\/zabbix_server.log' $USR/$Conf  #设置zabbix服务器日志存放位置
#zabbix_server要在网页配置完成后，在启动

#修改zabbix客户端配置文件，起服务
cp  $DIR/zabbix/zabbix-2.2.1/misc/init.d/fedora/core/zabbix_agentd  /etc/init.d/
chmod  +x /etc/init.d/zabbix_agentd 
sed -i '22s/local/local\/zabbix/' /etc/init.d/zabbix_agentd       #修改zabbix客户端配置文件
sed -i '/^Server=/cServer=127.0.0.1,'$IP'' $USR/$CONF             #设置zabbix服务器监控IP  
sed -i '/^ServerActive/cServerActive='$IP':10051'  $USR/$CONF     #设置zabbix服务器监控端口
sed -i '/^Hostname/cHostname=Zabbix_'$NAME''   $USR/$CONF         #设置zabbix服务器名
sed -i '/^LogFile/cLogFile=\/var\/log\/zabbix\/zabbix_agent.log' $USR/$CONF  #设置zabbix客户端日志存放位置

/etc/init.d/httpd restart             &>/dev/null
chkconfig httpd on                    &>/dev/null
/etc/init.d/zabbix_server restart     &>/dev/null
chkconfig zabbix_server on            &>/dev/null
/etc/init.d/zabbix_agentd restart     &>/dev/null
chkconfig zabbix_agentd on            &>/dev/null
echo "查看zabbix服务端口:"
netstat -anptu | grep zabbix       

#自定义监控配置,启用自定义key模块
#sed -i '/^# UnsafeUserParameters/cUnsafeUserParameters=1'  $USR/$CONF
#sed -i '/^# Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\//cInclude=\/usr\/local\/zabbix\/etc\/zabbix_agentd.conf.d/'  $USR/$CONF

#写自定义key模块测试
#echo "UserParameter=sumusers,wc -l /etc/passwd | awk '{print \$1}' "  >  $USR/zabbix_agentd.conf.d/sumusers.conf
#监控主机自定义key测试,需在监控服务器上自行添加该模块
#echo "您当前监控主机用户总数是:"
#/usr/local/zabbix/bin/zabbix_get  -s 127.0.0.1 -p 10050 -k sumusers
#被监控主机自定义key测试：注意被监控配置完成起服务后才能进行
#read -p " 请被监控主机的IP地址: "  ip
#/usr/local/zabbix/bin/zabbix_get  -s $ip -p 10050 -k sumusers


