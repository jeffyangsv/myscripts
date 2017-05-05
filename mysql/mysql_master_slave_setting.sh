#!/bin/bash   
##################################################
#Name:        mysql_master_slave_setting.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Setting Variables"
##################################################

_REMOTEHOST=192.168.1.51  #远程主机IP  
_LOCALHOST=192.168.1.52   #本地主机IP  
_USER=root                #用户名  
_REMOTEPASD=123456        #远程主机密码  
_LOCALPASD=123456         #本地主机密码  
_BASE=TSC  
 
_LF=`mysql -u root -h $_REMOTEHOST -p$_REMOTEPASD -e "show master status\G;" | awk '/File/ {print $2}'`  
_LLF=`mysql -u root -p$_LOCALPASD -e "show master status\G;" | awk '/File/ {print $2}'`  
_PS=`mysql -u root -h $_REMOTEHOST -p$_REMOTEPASD -e "show master status\G;" | awk '/Position/ {print $2}'`  
_LPS=`mysql -u root -p$_LOCALPASD -e "show master status\G;" | awk '/Position/ {print $2}'`  
 
# Backup Mysql   
mysqldump -u root -h $_REMOTEHOST -p$_REMOTEPASD  $_BASE > $_BASE.sql  
mysql -u root -p$_LOCALPASD $_BASE < $_BASE.sql  
rm -rf $_BASE.sql  
  
mysql -uroot -p$_LOCALPASD -e "stop slave;"  
mysql -h $_REMOTEHOST -uroot -p$_LOCALPASD -e "stop slave;"  
  
echo "mysql -uroot -p$_LOCALPASD -e +change master to master_REMOTEHOST=*${_REMOTEHOST}*,master_user=*${_USER}*,master_password=*${_REMOTEPASD}*,master_log_file=*${_LF}*,master_log_pos=${_PS};+" > tmp  
echo "mysql -h $_REMOTEHOST -uroot -p$_LOCALPASD -e +change master to master_REMOTEHOST=*${_LOCALHOST}*,master_user=*${_USER}*,master_password=*${_LOCALPASD}*,master_log_file=*${_LLF}*,master_log_pos=${_LPS};+" > tmp2  
sed -ri 's/\+/"/g' tmp  
sed -ri 's/\+/"/g' tmp2  
sed -ri "s/\*/\'/g" tmp  
sed -ri "s/\*/\'/g" tmp2  
sh tmp  
sh tmp2  
rm -rf tmp  
rm -rf tmp2  
mysql -uroot -p$_LOCALPASD -e "start slave;"  
mysql -h $_REMOTEHOST -uroot -p$_LOCALPASD -e "start slave;"  
mysql -uroot -p$_LOCALPASD -e "show slave status\G;" | awk '$0 ~/Host/ || $0 ~/State/'  
mysql -h $_REMOTEHOST -uroot -p$_LOCALPASD -e "show slave status\G;" | awk '$0 ~/Host/ || $0 ~/State/'  



