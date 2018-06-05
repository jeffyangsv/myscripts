#!/bin/bash
#------------------------------------------------------------
#Name:        
#Date：       2018-06-05
#Version:     v3.4.9
#Author:      GuoLikai(glk73748196@sina.com)
#Description: 部署zabbix3.4.9版本软件包
#------------------------------------------------------------

AppName=zabbix
AppProg=/usr/sbin/zabbix_server
Version='3.4.9'
PASSWD='adminroot'            #数据库用户root密码
User=zabbix       		#数据库zabbix授权用户
Sec=zabbix        		#数据库zabbix授权用户密码
IP=`ifconfig eth0 | grep inet | grep -v net6 |awk -F' ' '{print $2}'`  			#zabbix监控服务器ip地址
NAME=`ifconfig eth0 | grep inet | grep -v net6 |awk -F' ' '{print $2}'`   		#本机监控主机名
RpmDIr=/root/zabbix_src_3.4.9_el7

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "${AppName}_server" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
}

# 查询状态
fstatus()
{
    fpid
    if [ ! -f "$AppProg" ]; then
        echo "$AppName 未安装"
    else
        echo "$AppName 已安装"
        if [ -z "$AppMasterPid" ]; then
            echo "$AppName 未启动"
        else
            echo "$AppName 正在运行"
        fi
    fi
}

# 安装
finstall()
{
    fpid
    InstallFlag=1
    if [ -z "$AppMasterPid" ]; then
        test -f "$AppProg" && echo "$AppName 已安装"
        [ $? -ne 0 ] &&  finsdep && fupdate && fmariadb && fdatabase && fconf
    else
        echo "$AppName 正在运行"
    fi
}

finsdep()
{
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
}


#部署zabbix3.4服务
fupdate()
{
	useradd  -u 10002 zabbix  -s /sbin/nologin                  &>/dev/null
	cd ${RpmDIr}
	#wget ftp://ftp.icm.edu.pl/vol/rzm8/linux-fedora/linux/epel/7/x86_64/Packages/i/iksemel-1.4-6.el7.x86_64.rpm
	#wget http://rpmfind.net/linux/epel/7/x86_64/Packages/f/fping-3.10-4.el7.x86_64.rpm
	#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/php-mbstring-5.4.16-45.el7.x86_64.rpm
	#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/php-common-5.4.16-45.el7.x86_64.rpm
	#wget http://mirror.centos.org/centos/7/os/x86_64/Packages/php-bcmath-5.4.16-45.el7.x86_64.rpm
	yum -y localinstall iksemel-*.rpm fping-*.rpm php-*.rpm
	yum -y localinstall  zabbix-*.rpm                 &>/dev/null
}

# 配置Mysql数据库存储
fmariadb()
{
    systemctl start mariadb.service  &>/dev/null
	systemctl enable mariadb.service &>/dev/null
	yum -y install expect            &>/dev/null
expect <<EOF
spawn mysqladmin -u root -p password "${PASSWD}"  
expect  "Enter password:" 
send "\r"
expect eof
EOF
    echo "Mariadb数据库启动成功"
}



fdatabase()
{
    MysqlPid=$(ps ax | grep -w "mysqld" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    MysqlConn="mysql -uroot -p${PASSWD}"
    if [ -n "MysqlPid" ];then
	Result=$($MysqlConn -e "show databases" | grep -w "zabbix" | wc -l)
		if [ $Result -eq 0 ];then
			mysql -uroot -p${PASSWD} -e "create database zabbix character set utf8"                     		  &>/dev/null
			mysql -uroot -p${PASSWD} -e "grant all on zabbix.* to ${User}@localhost identified by  '${Sec}' "   &>/dev/null
			mysql -uroot -p${PASSWD} -e "flush privileges"   &>/dev/null
		else
			echo "$AppName 数据库已存在"
		fi
    else
        echo "mysql 数据库未启动"
    fi
}


fconf(){
	zcat /usr/share/doc/zabbix-server-mysql-${Version}/create.sql.gz | mysql -u${User} -p${Sec} zabbix
	sed -i "s@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g" /etc/httpd/conf.d/zabbix.conf
	cp ${RpmDIr}/simkai.ttf  /usr/share/zabbix/fonts/
	sed -i "s#graphfont#simkai#g" /usr/share/zabbix/include/defines.inc.php
	sed -i "/^function getLocales/{n;;n;n;n;n;s/false/true/}"  /usr/share/zabbix/include/locales.inc.php

	#修改zabbix服务器配置文件
	sed -i "/^DBName/cDBName=zabbix"               /etc/zabbix/zabbix_server.conf          #设置zabbix数据库名称
	sed -i "/^DBUser/cDBUser=${User}"              /etc/zabbix/zabbix_server.conf          #设置zabbix数据库账户
	sed -i "/^# DBPassword/cDBPassword=${Sec}"     /etc/zabbix/zabbix_server.conf          #设置zabbix数据库密码
	chown -R zabbix:zabbix /var/log/zabbix
	chown -R zabbix:zabbix /var/run/zabbix
	chmod -R 775 /var/log/zabbix/
	chmod -R 775 /var/run/zabbix/
	systemctl restart httpd
	systemctl restart zabbix-server
	systemctl enable  zabbix-server
	systemctl enable  httpd
	echo "查看zabbix服务端口:" && netstat -anptu | grep zabbix
}

fclient(){
	#rhel7客户端安装：
	sed -i "/^Server=/cServer=${IP}"    			/etc/zabbix/zabbix_agentd.conf        	#被动模式zabbix服务器地址  
	sed -i "/^ServerActive/cServerActive=${IP}"   	/etc/zabbix/zabbix_agentd.conf        	#被动模式zabbix服务器地址
	sed -i "/^Hostname/cHostname=${NAME}"  			/etc/zabbix/zabbix_agentd.conf        	#本机监控主机名
	systemctl restart zabbix-agent
	systemctl enable  zabbix-agent
}

# 启动
fstart()
{
    fpid
    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
        systemctl start ${AppName}-server
        sleep 1
        if [ -n "$(ps ax | grep "$AppName" | grep -v "grep" | awk '{print $1}' 2> /dev/null)" ]; then
           echo "$AppName 启动成功"
        else
           echo "$AppName 启动失败"
        fi
    fi
}

# 停止
fstop()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        systemctl stop  zabbix-server.service   &>/dev/null && echo "${AppName}-server 已停止 " || echo "$AppName-server 停止失败"
    else
        echo "$AppName 未启动"
    fi
}

# 终止进程
fkill()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        echo "$AppMasterPid" | xargs kill -9 &>/dev/null
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 主进程"
        else
            echo "终止 $AppName 主进程失败"
        fi
    else
        echo "$AppName 主进程未运行"
    fi
}

# 重启
frestart()
{
    fpid
    [ -n "$AppMasterPid" ] && fstop && sleep 1
    fstart
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) finstall;;
    "database"  ) fdatabase;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "status"    ) fstatus;;
    "restart"   ) frestart;;
    "kill"      ) fkill;;
    "client"    ) fclient;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile database             配置 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile status               状态 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    echo "$ScriptFile client               客户端 $AppName 安装"
    ;;
esac
