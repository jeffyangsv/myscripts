#!/bin/sh
##################################################
#Name:        osinit6.sh
#Version:     v1.0
#Create_Date：2016-6-6
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "脚本适用于Centos6的系统服务优化"
##################################################
ServiceList=$(chkconfig --list | grep '0' | awk '{print $1}' | grep -Ev 'sshd|network|crond|syslog')

for Service in $ServiceList
do
    /etc/init.d/$Service stop
    chkconfig --level 0123456 $Service off
done

# 内核参数调优
grep -q "net.ipv4.tcp_max_tw_buckets" /etc/sysctl.conf || cat >> /etc/sysctl.conf << EOF
########################################
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.somaxconn = 262144
net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 10000
net.ipv4.ip_local_port_range = 1024 65500
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_mem = 786432 1048576 1572864
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
vm.swappiness = 0
EOF
sysctl -p

grep -q "* soft nofile 60000" /etc/security/limits.conf || cat >> /etc/security/limits.conf << EOF
########################################
* soft nofile 60000
* hard nofile 65536
* soft nproc  2048
* hard nproc  16384
* soft stack  10240
* hard stack  32768
EOF

grep -q "ulimit -Sn 60000" /etc/profile || cat >> /etc/profile << EOF
########################################
ulimit -Sn 60000
ulimit -Hn 65536
ulimit -Su 2048
ulimit -Hu 16384
ulimit -Ss 10240
ulimit -Hs 32768

alias grep='grep --color=auto'
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
EOF

# 禁用并关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

# 优化SSH
sed -i 's/.*UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
/etc/init.d/sshd restart

# 脚本目录加入PATH
grep -q "/App/script" $HOME/.bash_profile || cat >> $HOME/.bash_profile << EOF
########################################
export PATH=/App/script:\$PATH
EOF

# 添加dns
cat >> /etc/resolv.conf << EOF
nameserver 202.106.0.20
nameserver 223.5.5.5
EOF

# 安装基础应用
yum -y --skip-broken install ntpdate screen wget rsync curl gcc vim-enhanced xz iftop sysstat dstat htop iotop lrzsz

# 创建基础文件夹
mkdir -p /App/script/{SRT,OPS} /App/src/{SRT,OPS} /App/build/{SRT,OPS} /App/install/{SRT,OPS} /App/conf/{SRT,OPS} /App/log/{SRT,OPS} /App/opt/{SRT,OPS} /App/mnt/{UGC,RES} /App/data /App/backup/HOST

# 换repo源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
wget http://mirrors.aliyun.com/repo/epel-6.repo -O /etc/yum.repos.d/epel-6.repo
wget http://mirrors.aliyun.com/repo/Centos-6.repo -O /etc/yum.repos.d/CentOS-Base.repo

# 安装插件
yum -y install python-simplejson libselinux-python

# Vim添加配置

cat >> /etc/vimrc << EOF
set number
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set expandtab
set nobackup
set wrap

syntax on
filetype plugin indent on
syntax enable
set cursorline
set t_Co=256
colorscheme molokai
autocmd BufNewFile,BufRead * :syntax match cfunctions "\<[a-zA-Z_][a-zA-Z_0-9]*\>[^()]*)("me=e-2
autocmd BufNewFile,BufRead * :syntax match cfunctions "\<[a-zA-Z_][a-zA-Z_0-9]*\>\s*("me=e-1"))"
hi cfunctions ctermfg=81
hi Type ctermfg=118 cterm=none
hi Structure ctermfg=118 cterm=none
hi Macro ctermfg=161 cterm=bold
hi PreCondit ctermfg=161 cterm=bold
EOF                                               

# 挂载tmpfs文件系统
mount --bind /dev/shm /tmp
grep -q "/dev/shm" /etc/rc.local || echo "/bin/mount --bind /dev/shm /tmp" >> /etc/rc.local

# 设置时间服务器
#cat > /var/spool/cron/root << EOF
#0  *  *  *  *  /usr/sbin/ntpdate 192.168.10.2 &> /dev/null
#EOF
#ntpdate 192.168.10.2 &> /dev/null


#创建密钥
mkdir /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxWNKngBgnhFsNgNLb1gmo99UwUvBxQU4qIJtrAOM5c+uf1FJXoeWyXp7oHEBcGjCPI9C/lQ6gJLKhz59TeondyNfBC6YzEqdwmOxNCh
m8UwpuiZlyNQz3KzFgZOvxXiqnq6iKgVQrKh/V4d4mroqojVu2i19e3CAfbgwom4uosHsD4uMZlqJ5Z7/LI/ZymVOphzR1tgBAhA25dlxa0gJOMEKfYjFUG7SFMVKWJfzKdL2g2UsjzRUWBxH
dnyFyt3hMXThLsAF+gBv5KqMjVXfXxfqEVeiDE6xijRzZ42keKc/JPRU5bmiVcVTxrwlMnMXbT02EM9twB/yrlBcPHvxdw== root@localhost.localdomain' >> /root/.ssh/author
ized_keys
chmod 600 /root/.ssh/authorized_keys
