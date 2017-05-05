#!/bin/bash
##################################################
#Name:        mysql_master_slave.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Auto-mysql_master-slave"
##################################################

#---------------------------------菜单--------------------------------------
echo "----------------------------------------------------"
echo -e "\033[36m----------欢迎使用Mysql主从自动搭建平台-------------\033[0m"
echo "----------------------------------------------------"
echo "请按照选项进行安装及部署："
echo "----------------------------------------------------"
echo "|【install】| 软件包下载及安装                     |"
echo "----------------------------------------------------"
echo "|【server】 | Mysql服务调整                        |"
echo "----------------------------------------------------"
echo "|【master】 | Master部署                           |"
echo "----------------------------------------------------"
echo "|【slave】  | Slave部署                            |"
echo "----------------------------------------------------"
echo "|【monitor】| 查看监控状态                         |"
echo "----------------------------------------------------"
echo "|【help】   | 帮助                                 |"
echo "----------------------------------------------------"
echo "|【q】      | 退出                                 |"
echo "----------------------------------------------------"
#---------------------------------下载安装------------------------
function HELP (){
echo -e "\033[33m
-------------------------------------------------------------------------
（1）该脚本可在任意路径运行。
（2）可手动按需求选择选项进行安装及状态查看。
（3）该脚本安装的mysql默认无密码，可在脚本安装后自行设定mysql密码。
（4）该脚本安装的mysql版本为-5.6.25,若需要其他版本请更改脚本内的软件源。
（5）该脚本需要手动指定IP、同步用户名、同步密码，按照提示输入即可
-------------------------------------------------------------------------\033[0m"
}
#------------------------------------help--------------------------
function INSTALL (){
mkdir /mysqldir ; cd /mysqldir
echo -e "\033[35m正在下载软件包,请等待……\033[0m"
wget http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.25.tar.gz &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35m软件包下载成功！\033[0m"
else
        echo -e "\033[35m软件包下载失败，请检查网络或下载源！\033[0m"   
        exit
fi
echo -e "\033[35m正在解压软件包……\033[0m"
tar vxf mysql-5.6.25.tar.gz &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35m解压成功！\033[0m"
else
        echo -e "\033[35m解压失败！\033[0m"
        exit
fi
cd mysql-5.6.25
echo -e "\033[35m正在安装cmake软件包……\033[0m"
yum install cmake -y &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35mcmake安装成功！\033[0m"
else
        echo -e "\033[35mcmake安装失败！\033[0m"
        exit
fi
echo -e "\033[35m正在安装mysql，时间较长请耐心等待……\033[0m"
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql5.6 &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35mmysql预编译成功！\033[0m"
else
        echo -e "\033[35mmysql预编译失败！\033[0m"
        exit
fi
make && make install
if [ $? -eq 0 ];then
        echo-e  "\033[35mmysql安装成功！\033[0m"
else
        echo-e  "\033[35mmysql安装失败！\033[0m"
        exit
fi
}
#---------------------------------服务调整-----------------------------------
function SERVER (){
echo -e "\033[35m添加mysql用户……\033[0m"
chown -R mysql.mysql /usr/local/mysql5.6
cd /usr/local/mysql5.6/
echo -e "\033[35mmysql初始化mysql……\033[0m"
scripts/mysql_install_db --user=mysql &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35mmysql初始化成功！\033[0m"
else
        echo -e "\033[35mmysql初始化失败！\033[0m"
        exit
fi
echo -e "\033[35m重启mysql服务……\033[0m"
service mysql start &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35mmysql服务启动成功！\033[0m"
else
        echo -e "\033[35mmysql服务启动失败！\033[0m"
        exit
fi
alias mysql='/usr/local/mysql5.6/bin/mysql'
echo -e "\033[35m关闭防火墙……\033[0m"
service iptables stop &>/dev/null
}
#---------------------------------Master部署----------------------------------
function MASTER (){
cat /etc/my.cnf |grep "log-bin=mysql-bin"
if [ $? -eq 0 ];then
        echo -e "\033[35m配置信息导入成功！\033[0m"     
fi
echo -e "\033[35m重启mysql服务……\033[0m"        
service mysql restart &>/dev/null
if [ $? -eq 0 ];then
fi
read -p "请输入slave服务器IP:" i
read -p "请输入同步使用的用户名:" USER_MY
read -p "请输入同步使用的密码:" PASS_MY
/usr/local/mysql5.6/bin/mysql -uroot -e "flush privileges;"
echo -e "\033[36m您的mysql-编号为：$MY_BIN\033[0m"
echo -e "\033[36m您的mysql-POS点为：$MY_POS\033[0m"
}
#---------------------------------Slave部署-----------------------------------
function SLAVE (){
cat /etc/my.cnf |grep "server-id = 2"
if [ $? -eq 0 ];then
        echo -e "\033[35mmysql配置信息已存在。\033[0m"
else
        sed -i 's/\[mysqld\]/&\nserver-id = 2/' /etc/my.cnf
        echo -e "\033[35mmysql配置信息导入成功！\033[0m"
fi
echo -e "\033[35m重启mysql服务……\033[0m"
service mysql restart &>/dev/null
if [ $? -eq 0 ];then
        echo -e "\033[35mmysql服务启动成功！\033[0m"
else
        echo -e "\033[35mmysql服务启动失败！\033[0m"
        exit
fi
read -p "请输入master服务IP：" i
read -p "请输入master mysql-编号：" MY_BIN
read -p "请输入master mysql-POS：" MY_POS
read -p "请输入同步使用的用户名:" USER_MY
read -p "请输入同步使用的密码:" PASS_MY
/usr/local/mysql5.6/bin/mysql -uroot -e "flush privileges;"
/usr/local/mysql5.6/bin/mysql -uroot -e "start slave;"
}
#---------------------------------监控同步状态-------------------------------
function MONITOR (){
if [[ $SLAVE_IO = Yes ]];then
        echo -e "\033[36mThe Slave_IO is Yes!\033[0m"
elif [[ $SLAVE_IO = Connecting ]];then
        echo -e "\033[36m请检查您的防火墙配置！\033[0m"
else
        echo -e "\033[36mThe Slave_IO is NO!\033[0m"
        exit
fi
if [[ $SLAVE_SQL = Yes ]];then
        echo -e "\033[36mThe Slave_IO is Yes!\033[0m"
elif [[ $SLAVE_SQL = Connecting ]];then
        echo -e "\033[36m请检查您的防火墙配置！\033[0m"
else
        echo -e "\033[36mThe Slave_IO is NO!\033[0m"
        exit
fi
if [[ $SLAVE_IO = Yes && $SLAVE_SQL = Yes ]];then
        echo -e "\033[35mMysql主从同步建立成功！\033[0m"
else
        echo -e "\033[35mMysql主从同步建立失败！\033[0m"
fi
}
#--------------------------------模块调用-------------------------------------
read -p "请输入您要进行的选项：" i
PATH_AUTO=$(pwd)
case $i in
        install)
        INSTALL
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        server)
        SERVER
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        master)
        MASTER
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        slave)
        SLAVE
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        monitor)
        MONITOR
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        help)
        HELP
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
        q)
        exit
        ;;
        *)
        echo -e "\033[36m请输入正确选项！\033[0m"
        cd $PATH_AUTO ; sh auto_mysql_M-S.sh
        ;;
esac

