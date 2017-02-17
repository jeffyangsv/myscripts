#!/bin/bash
##################################################
#Name:        kvm_clone_later.sh
#Version:     v1.0
#Create_Date：2016-6-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "KVM克隆后执行的脚本"
##################################################

#快速搭建LAMP平台
read -p "请输入要修改的主机名：" Host
read -p "请添加管理员账户：" Name
read -p "请输入要修改的管理员密码：" Sec
#Host=puppet.glk.com
useradd -G  root  $Name
echo $Sec | passwd --stdin  $Name     &>/dev/null
sed -i '/^HOSTNAME/s/=.*/='$Host'/'  /etc/sysconfig/network
rm -rf /etc/yum.repos.d/*         &>/dev/null
yum-config-manager --add http://192.168.4.254/rhel6  &>/dev/null
sed -i '$agpgcheck=0' /etc/yum.repos.d/192.168.4.254_rhel6.repo    &>/dev/null
yum -y install httpd  mysql mysql-server  php php-mysql &>/dev/null
service httpd restart             &>/dev/null
service mysqld restart            &>/dev/null
chkconfig httpd on                &>/dev/null
chkconfig mysqld on               &>/dev/null
echo "<?php
phpinfo()
?>"  > /var/www/html/index.php

