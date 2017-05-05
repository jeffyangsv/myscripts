!/bin/bash
##################################################
#Name:        nagios_server.sh
#Version:     v1.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Nagios软件部署"
##################################################

read -p " 请输入nagios监控远端主机的ip地址: " IP
read -p " 请输入nagios监控远端主机的ip主机位: " Host
read -p " 请输入nagios监控服务器的ip地址: " Nagip
yum -y  install httpd php* gcc   gcc-c++  &>/dev/null
yum -y install openssl*   &>/dev/null
yum -y install xinetd     &>/dev/null
yum -y install expect     &>/dev/null
echo “test web” > /var/www/html/index.html
service   httpd  restart    &>/dev/null
chkconfig httpd  on       &>/dev/null

useradd nagios            &>/dev/null
groupadd nagcmd           &>/dev/null
usermod -G   nagcmd  nagios  &>/dev/null
usermod -G   nagcmd  apache  &>/dev/null
cd /root/
unzip  nagios.zip         &>/dev/null
cd /root/nagios/
tar -zxvf nagios-3.2.1.tar.gz &>/dev/null        #nagios软件安装

cd /root/nagios/nagios-3.2.1
./configure  --with-nagios-user=nagios  --with-nagios-group=nagcmd --with-command-user=nagios  --with-command-group=nagcmd     &>/dev/null
make all                  &>/dev/null
make install              &>/dev/null
make install-init         &>/dev/null
make install-config       &>/dev/null
make install-commandmode  &>/dev/null
make install-webconf      &>/dev/null
cd /root/nagios/                                 #nagios插件安装
tar xf nagios-plugins-1.4.14.tar.gz
./configure --with-nagios-user=nagios --with-nagios-group=nagcmd    &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
service   nagios  restart    &>/dev/null
chkconfig nagios  on       &>/dev/null

tar xf nrpe-2.12.tar.gz   &>/dev/null            #nrpe包安装
cd /root/nagios/nrpe-2.12/
./configure               &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
make install-plugin       &>/dev/null
make install-daemon       &>/dev/null
make install-daemon-config     &>/dev/null
make install-xinetd            &>/dev/null
chkconfig nrpe on               &>/dev/null
sed -i  's/127.0.0.1/127.0.0.1 '$IP'  '$Nagip'/'  /etc/xinetd.d/nrpe
sed -i '$anrpe        5666/tcp       #nrpe service' /etc/services
service xinetd restart          &>/dev/null
