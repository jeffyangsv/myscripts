#!/bin/bash
##################################################
#Name:        grafana_install.sh
#Version:     v1.0
#Create_Date：2016-12-12
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Centos7上部署Grafana-3.1.1源码包"
##################################################

PASSWD=123456           #数据库用户root密码
MYSQLIP=172.16.1.200    #数据库地址
USER=grafana            #数据库grafana授权用户
PASSWORD=grafana        #数据库grafana授权用户密码
useradd -s /sbin/nologin grafana
mkdir /etc/grafana/
mkdir /var/log/grafana
mkdir -p /var/lib/grafana/{dashboards,sessions,plugins}
chown -R grafana:grafana /var/lib/grafana
chown -R grafana:grafana /var/log/grafana
mysql -uroot -p${PASSWD} -e "create database grafana;"
mysql -uroot -p${PASSWD} -e "grant all on grafana.* to '$USER'@'172.16.1.0/255.255.255.0' identified by '$PASSWORD';"
mysql -h${MYSQLIP} -u${USER} -p${PASSWORD} -e "show databases;"
wget https://grafanarel.s3.amazonaws.com/builds/grafana-3.1.1-1470047149.linux-x64.tar.gz
tar -zxvf grafana-3.1.1-1470047149.linux-x64.tar.gz  
mv grafana-3.1.1-1470047149  /usr/local/grafana
cp -rp /usr/local/grafana/bin/grafana-server /usr/sbin/grafana-server
cp -rp /usr/local/grafana/bin/grafana-cli    /usr/sbin/grafana-cli
cp -rp /usr/local/grafana/conf/sample.ini    /etc/grafana/grafana.ini
sed -i '/^;logs = \/var\/log\/grafana/clogs = \/var\/log\/grafana/'   /etc/grafana/grafana.ini
sed -i '/;plugins/cplugins = /var/lib/grafana/plugins'    /etc/grafana/grafana.ini
sed -i '/;type = sqlite3/ctype = mysql'   /etc/grafana/grafana.ini
sed -i "/;host = 127.0.0.1:3306/chost =$MYSQLIP:3306" /etc/grafana/grafana.ini
sed -i '/;name = grafana/cname = grafana'   /etc/grafana/grafana.ini
sed -i '/;user = root/cuser = grafana'      /etc/grafana/grafana.ini
sed -i '/;password =/cpassword = grafana'   /etc/grafana/grafana.ini
sed -i '/\[dashboards.json\]/{n;s#;##}'     /etc/grafana/grafana.ini
sed -i '/\[dashboards.json\]/{n;s#false#true#}'  /etc/grafana/grafana.ini
sed -i '/\[dashboards.json\]/{n;n;s#;##}'   /etc/grafana/grafana.ini
#Grafana-Zabbix插件安装
grafana-cli plugins list-remote   &> /dev/null
grafana-cli plugins install alexanderzobnin-zabbix-app  &> /dev/null
echo "部署Grafana-3.1.1源码包 ok"
echo "GRAFANA_USER=grafana
GRAFANA_GROUP=grafana
GRAFANA_HOME=/usr/local/grafana
LOG_DIR=/var/log/grafana
DATA_DIR=/var/lib/grafana
MAX_OPEN_FILES=10000
CONF_DIR=/etc/grafana
CONF_FILE=/etc/grafana/grafana.ini
RESTART_ON_UPGRADE=false
PLUGINS_DIR=/var/lib/grafana/plugins" > /etc/sysconfig/grafana-server
echo "[Unit]
Description=Grafana Server
Documentation=http://docs.grafana.org
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=-/etc/sysconfig/grafana-server
User=grafana
Group=grafana
Type=simple
Restart=on-failure
WorkingDirectory=/usr/local/grafana
ExecStart=/usr/local/grafana/bin/grafana-server                   \
                            --config=\${CONF_FILE}                 \
                            --pidfile=\${PID_FILE}                 \
                            cfg:default.paths.logs=\${LOG_DIR}     \
                            cfg:default.paths.data=\${DATA_DIR}    \
                            cfg:default.paths.plugins=\${PLUGINS_DIR}
LimitNOFILE=10000
TimeoutStopSec=20

[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/grafana-server.service
systemctl daemon-reload 
systemctl start grafana-server.service
systemctl enable grafana-server.service
netstat -anptu | grep 3000

