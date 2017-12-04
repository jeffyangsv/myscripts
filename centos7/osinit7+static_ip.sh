#!/bin/bash
##################################################
#Name:        osinit7.sh
#Version:     v1.0
#Create_Date：2017-4-3
#Author:      GuoLikai(glk73748196@sina.com)
#ISO:		  CentOS-7-x86_64-Minimal-1611.iso
#Description: "脚本适用于Centos7的系统服务优化"
##################################################

cat << EOF
+--------------------------------------------------------------+
|          === Welcome to CentOS 7.x System init ===           |
+--------------------------------------------------------------+
+---------------------------by GuoLikai--------------------------+
EOF

# 添加dns
cat >> /etc/resolv.conf << EOF
nameserver 202.106.0.20
nameserver 223.5.5.5
EOF

#关闭selinux和防火墙
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
setenforce 0
systemctl stop firewalld.service
systemctl disable firewalld.service

# 安装基础应用
yum -y --skip-broken install ntp ntpdate screen wget curl curl-devel

# 创建基础文件夹
mkdir -p /App/script/{SRT,OPS} /App/src/{SRT,OPS} /App/build/{SRT,OPS} /App/install/{SRT,OPS} /App/conf/{SRT,OPS} /App/log/{SRT,OPS} /App/opt/{SRT,OPS} /App/mnt/{UGC,RES} /App/data /App/backup/{HOST,SRT,OPS}
# 换repo源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
#sed -i "/gpgcheck=1/cgpgcheck=0" /etc/yum.repos.d/*.repo
wget http://mirrors.aliyun.com/repo/epel-7.repo -O /etc/yum.repos.d/epel-7.repo
wget http://mirrors.aliyun.com/repo/Centos-7.repo -O /etc/yum.repos.d/CentOS-Base.repo
wget http://mirrors.163.com/.help/CentOS7-Base-163.repo -O /etc/yum.repos.d/epel-163.repo

# 安装插件
yum -y  groupinstall "开发工具"
yum -y --skip-broken install gcc vim vim-enhanced xz iftop sysstat dstat htop iotop lrzsz tree telnet dos2unix  net-tools   unzip sudo
yum -y install python-simplejson libselinux-python

# 设置静态IP
ETH_NUM=$(ip addr|egrep "inet+"|egrep "brd+"|grep -v "lo:"|awk '{print $NF}'|wc -l)
#for i in $(seq 0 $[$ETH_NUM-1])
for i in $(seq 0 $ETH_NUM)
do
#mv /etc/sysconfig/network-scripts/ifcfg-eth$i /etc/sysconfig/network-scripts/ifcfg-eth$i.bak
cat > /etc/sysconfig/network-scripts/ifcfg-eth$i << EOF
DEVICE=eth$i
NAME=eth$i
TYPE=Ethernet
BOOTPROTO=static
ONBOOT=yes
IPV6INIT=no
IPADDR=$(ifconfig eth$i | grep 'inet ' | awk '{print $2}' | head -1)
NETMASK=$(ifconfig eth$i | grep mask | awk '{print $4}'| head -1) 
GATEWAY=$(route -n | grep UG | awk '{print $2}' | head -1)
EOF
done

#set ntp
echo "#time sync"  >> /var/spool/cron/root
echo "0 * * * * /usr/sbin/ntpdate time.nist.gov > /dev/null 2>&1" >> /var/spool/cron/root
systemctl restart crond

#set ulimit
echo "ulimit -SHn 102400" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*           soft   nofile       102400
*           hard   nofile       102400
*           soft   nproc        102400
*           hard   nproc        102400
EOF

#set ssh
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
#sed -i 's/#Port 22/Port 6343/' /etc/ssh/sshd_config
systemctl restart sshd

#set sysctl
true > /etc/sysctl.conf
cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 25000 65535
EOF
/sbin/sysctl -p
echo "sysctl set OK!!"

#vim setting
sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
cat >> /etc/vimrc << EOF
set fenc=utf-8 "设定默认解码
set fencs=utf-8,usc-bom,euc-jp,gb18030,gbk,gb2312,cp936
set nocp "或者 set nocompatible 用于关闭VI的兼容模式
set number "显示行号
set ai "或者 set autoindent vim使用自动对齐，也就是把当前行的对齐格式应用到下一行
set si "或者 set smartindent 依据上面的对齐格式，智能的选择对齐方式
set tabstop=4 "设置tab键为4个空格
set sw=4 "或者 set shiftwidth 设置当行之间交错时使用4个空格
set ruler "设置在编辑过程中,于右下角显示光标位置的状态行
set incsearch "设置增量搜索,这样的查询比较smart
set showmatch "高亮显示匹配的括号
set matchtime=5 "匹配括号高亮时间(单位为 1/10 s)
set ignorecase "在搜索的时候忽略大小写
set backspace=indent,eol,start "Backspace支持使用"
syntax on
EOF

# 脚本目录加入PATH
grep -q "/App/script" $HOME/.bash_profile || cat >> $HOME/.bash_profile << EOF
########################################
export PATH=/App/script:\$PATH
EOF
cat << EOF
+--------------------------------------------------------------+
|                    ===System init over===                    |
+--------------------------------------------------------------+
+---------------------------by GuoLikai--------------------------+
EOF
echo "###############################################################"
