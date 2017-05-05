#!/bin/bash
##################################################
#Name:        nagios_client6.sh
#Version:     v1.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Nagios软件部署"
##################################################



read -p " 请输入nagios监控远端主机的ip地址: " IP
read -p " 请输入nagios监控远端主机的ip主机位: " Host
read -p " 请输入nagios监控服务器的ip地址: " Nagip

Nrpe=/usr/local/nagios/etc/nrpe.cfg
Usr=/usr/local/nagios
yum -y install openssl*   &>/dev/null
yum -y install xinetd     &>/dev/null
chkconfig xinetd on       &>/dev/null
service xinetd start      &>/dev/null
useradd   nagios          &>/dev/null
groupadd  nagcmd          &>/dev/null
cd /root/
unzip  nagios.zip         &>/dev/null
cd /root/nagios/
tar xf nagios-plugins-1.4.14.tar.gz  &>/dev/null
./configure               &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
cd /root/nagios/
tar xf nrpe-2.12.tar.gz   &>/dev/null     
cd /root/nagios/nrpe-2.12/
./configure               &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
make install-plugin       &>/dev/null
make install-daemon       &>/dev/null
make install-daemon-config     &>/dev/null
make install-xinetd            &>/dev/null
cd /root/
sed -i  '/^command\[/d' $Nrpe 
sed -i  '$acommand[check_'$Host'_users]='$Usr'/libexec/check_users -w 3 -c 5'  $Nrpe
sed -i  '$acommand[check_'$Host'_load]='$Usr'/libexec/check_load -w 15,10,5 -c 30,25,20'  $Nrpe
sed -i  '$acommand[check_'$Host'_boot]='$Usr'/libexec/check_disk -w 20% -c 10% -p /boot'  $Nrpe
sed -i  '$acommand[check_'$Host'_root]='$Usr'/libexec/check_disk -w 20% -c 10% -p /'  $Nrpe
sed -i  '$acommand[check'$Host'_zombie_procs]='$Usr'/libexec/check_procs -w 5 -c 10 -s Z' $Nrpe
sed -i  '$acommand[check_'$Host'_procs]='$Usr'/libexec/check_procs -w 90  -c 120'  $Nrpe
chkconfig nrpe on               &>/dev/null
sed -i  "s/127.0.0.1/127.0.0.1 '$IP'  '$Nagip'/"  /etc/xinetd.d/nrpe
sed -i '$anrpe        5666/tcp       #nrpe service' /etc/services
service xinetd restart          &>/dev/null
echo "nagios监控远端主机软件包安装完成"
netstat -anptu | grep :5666
echo "测试本机已登录的用户数"
/usr/local/nagios/libexec/check_nrpe -H ${IP} -c  check_${Host}_users
echo "运行的总进程数"
/usr/local/nagios/libexec/check_nrpe -H ${IP} -c  check_${Host}_procs
echo "根分区的使用量"
/usr/local/nagios/libexec/check_nrpe -H ${IP} -c  check_${Host}_boot
echo "引导分区的使用量"
/usr/local/nagios/libexec/check_nrpe -H ${IP} -c  check_${Host}_root



