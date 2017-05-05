!/bin/bash
##################################################
#Name:        nagios_server6.sh
#Version:     v1.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Nagios软件部署"
##################################################


read -p " 请输入nagios监控远端主机的ip地址: " IP
read -p " 请输入nagios监控远端主机的ip主机位: " Host
read -p " 请输入nagios监控服务器的ip地址: " Nagip

#nagios环境准备
yum -y  install httpd php* gcc   gcc-c++  &>/dev/null #nagios依赖包
yum -y  install openssl*  xinetd expect    &>/dev/null  #nrpe依赖包

echo “test web” > /var/www/html/index.html
service   httpd  restart     &>/dev/null
chkconfig httpd  on          &>/dev/null

useradd nagios               &>/dev/null
groupadd nagcmd              &>/dev/null
usermod -G   nagcmd  nagios  &>/dev/null
usermod -G   nagcmd  apache  &>/dev/null

#安装nagios
cd /root
unzip  /root/nagios.zip              &>/dev/null
cd /root/nagios/
#解压nagios主软件包
tar -zxvf /root/nagios/nagios-3.2.1.tar.gz  &>/dev/null      
cd /root/nagios/nagios-3.2.1
./configure  --with-nagios-user=nagios  --with-nagios-group=nagcmd --with-command-user=nagios  --with-command-group=nagcmd     &>/dev/null
make 
make all                  &>/dev/null
make install              &>/dev/null     #This installs the main program, CGIs, and HTML files 主程序
make install-init         &>/dev/null     #This installs the init script in /etc/rc.d/init.d 服务脚本
make install-config       &>/dev/null	  #设置权限
make install-commandmode  &>/dev/null     #安装模板文件
make install-webconf      &>/dev/null     #网站配置文件、接口

#nagios插件安装(libexec)
cd /root/nagios/                          
tar xf nagios-plugins-1.4.14.tar.gz
./configure  --with-nagios-user=nagios  --with-nagios-group=nagcmd --with-command-user=nagios  --with-command-group=nagcmd        &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
#ls /usr/local/nagios/libexec/check_* #确认插件是否安装成功
service   nagios  restart &>/dev/null
chkconfig nagios  on      &>/dev/null

#创建认证用户(用户信息/etc/httpd/conf.d/nagios.conf、/usr/local/nagios/etc/cgi.cfg )
expect <<EOF
spawn htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
expect "New password:"
send "123456\r"
expect "Re-type new password"
send "123456\r"
expect eof
EOF
service   httpd  restart

#验证主配置文件是否有误
#ERR=`/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg  | grep "Total Errors" | awk '{print $3}'`
#if [ $ERR -ne 0 ];then
#echo "配置文件有误，请检查"
#fi  

#nrpe包安装
cd  /root/nagios
tar xf nrpe-2.12.tar.gz   &>/dev/null           
cd /root/nagios/nrpe-2.12/
./configure               &>/dev/null
make                      &>/dev/null
make install              &>/dev/null
make install-plugin       &>/dev/null
make install-daemon       &>/dev/null
make install-daemon-config     &>/dev/null
make install-xinetd            &>/dev/null

chkconfig nrpe on              &>/dev/null
sed -i  "s/127.0.0.1/127.0.0.1 '$IP'  '$Nagip'/"  /etc/xinetd.d/nrpe
sed -i '$anrpe        5666/tcp       #nrpe service' /etc/services
service xinetd restart          &>/dev/null
