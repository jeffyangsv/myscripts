#!/bin/bash
##################################################
#Name:        zabbix_agent6.sh
#Version:     v2.0
#Create_Date：2016-7-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Linux服务器部署zabbix软件包"
##################################################

#Date：2016-6-10
#Version:v1.0
#Author:GuoLikai(glk73748196@sina.com)
#Description:在被监控主机安装zabbix软件包

read -p "请输入zabbix监控服务器的IP地址："  IP
read -p "请设置zabbix被监控主机名："  Name
read -p " 请输入zabbixdb压缩包完整路径: " DIR
CONF=zabbix_agentd.conf
USR=/usr/local/zabbix/etc
yum -y install gcc gcc+                &>/dev/null
useradd zabbix                         &>/dev/null
echo '123456' | passwd --stdin zabbix  &>/dev/null
unzip -d $DIR  $DIR/zabbix.zip         &>/dev/null
cd $DIR/zabbix
tar xf zabbix-2.2.1.tar.gz             &>/dev/null
cd zabbix-2.2.1
./configure --prefix=/usr/local/zabbix --enable-agent  &>/dev/null
make                                   &>/dev/null
make install                           &>/dev/null
#被监控主机上修改zabbix_agent启动程序文件、主配置文件，起服务
cp  $DIR/zabbix/zabbix-2.2.1/misc/init.d/fedora/core/zabbix_agentd  /etc/init.d/
chmod +x /etc/init.d/zabbix_agentd 
sed -i  '22s/local/local\/zabbix/' /etc/init.d/zabbix_agentd  #修改zabbix客户端启动配置文件
sed -i '/^Server=/cServer=127.0.0.1,'$IP''   $USR/$CONF       #设置zabbix服务器监控IP
sed -i '/^ServerActive/cServerActive='$IP':10051'  $USR/$CONF #设置zabbix服务器监控端口
sed -i '/^Hostname/s#=.*#='$Name'#'   $USR/$CONF              #设置zabbix客户端名
mkdir /var/log/zabbix
sed -i '/^LogFile/cLogFile=\/var\/log\/zabbix\/zabbix_agent.log' $USR/$Conf #设置zabbix客户端日志存放位置
#自定义监控配置,启用自定义key模块
sed -i '/^# UnsafeUserParameters/cUnsafeUserParameters=1'  $USR/$CONF
sed -i '/^# Include=\/usr\/local\/etc\/zabbix_agentd.conf.d\//cInclude=\/usr\/local\/zabbix\/etc\/zabbix_agentd.conf.d/'  $USR/$CONF
#写自定义key模块测试
#echo "UserParameter=sumusers,wc -l /etc/passwd | awk '{print \$1}' "  >  $USR/zabbix_agentd.conf.d/sumusers.conf
/etc/init.d/zabbix_agentd restart
chkconfig zabbix_agentd on
netstat -anptu | grep zabbix_agentd
#被监控主机自定义key测试
#echo "您当前主机用户总数是:"
#/usr/local/zabbix/bin/zabbix_get  -s 127.0.0.1 -p 10050 -k sumusers
#监控服务主机上测试
#/usr/local/zabbix/bin/zabbix_get  -s $IP  -p 10050 -k sumusers
mv /root/zabbix /var/tmp/
