#Kickstart file automatically

#platform=x86, AMD64, or Intel EM64T
# System authorization information
authconfig --useshadow --passalgo=sha512
# System bootloader configuration
bootloader --location=mbr
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --enabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang zh_CN.UTF-8
# Use network installation
url --url=$tree
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Reboot after installation
reboot

#Root password
rootpw --iscrypted $default_password_crypted
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone Asia/Shanghai 
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr
# Allow anaconda to partition the system as needed
#autopart
part /boot --fstype=ext4 --size=200
part / --fstype=ext4 --size=10240
part swap --size=1024
part /App --fstype=ext4 --grow --size=200

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
ServiceList=`chkconfig --list | grep '0' | awk '{print $1}' | grep -Ev 'sshd|network|crond|syslog|auditd'`
for Service in $ServiceList
do
/etc/init.d/$Service stop
chkconfig --level 0123456 $Service off
done

cat >> /etc/sysctl.conf << EOF
vm.swappiness = 0
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
fs.inotify.max_user_watches = 1048576
kernel.hung_task_timeout_secs = 0
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.overcommit_memory = 1
EOF
sysctl -p

cat >> /etc/security/limits.conf << EOF
* - nofile 1048576
* - nproc  65536
* - stack  1024
EOF

cat >> /etc/profile << EOF
ulimit -n 1048576
ulimit -u 65536
ulimit -s 1024
alias grep='grep --color=auto'
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
EOF

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0

sed -i 's/.*UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/.*GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
/etc/init.d/sshd restart

mkdir -p /App/script/{SRT,OPS} /App/src/{SRT,OPS} /App/build/{SRT,OPS} /App/install/{SRT,OPS} /App/conf/{SRT,OPS} /App/log/{SRT,OPS} /App/opt/{SRT,OPS} /App/mnt/{UGC,RES} /App/data /App/backup/HOST

mount --bind /dev/shm /tmp
echo "/bin/mount --bind /dev/shm /tmp" >> /etc/rc.local
yum -y --skip-broken install wget

mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
wget http://mirrors.aliyun.com/repo/epel-6.repo -O /etc/yum.repos.d/epel-6.repo
wget http://mirrors.aliyun.com/repo/Centos-6.repo -O /etc/yum.repos.d/CentOS-Base.repo

yum -y --skip-broken install ntpdate screen wget rsync curl gcc vim-enhanced xz iftop sysstat dstat htop iotop lrzsz

cat > /var/spool/cron/root << EOF
0  *  *  *  *  /usr/sbin/ntpdate time.nist.gov  &> /dev/null
EOF

wget http://172.16.1.3/cobbler/vim/molokai.vim -O /usr/share/vim/vim74/colors/molokai.vim
#wget -r http://172.16.1.3/cobbler/zabbix/ -O /App/src/OPS/
#wget http://172.16.1.3/cobbler/ipinit.sh -O /App/script/OPS/ipinit.sh
#wget http://172.16.1.3/yanxiu.repo -O /etc/yum.repos.d/yanxiu.repo

mkdir /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxWNKngBgnhFsNgNLb1gmo99UwUvBxQU4qIJtrAOM5c+uf1FJXoeWyXp7oHEBcGjCPI9C/lQ6gJLKhz59TeondyNfBC6YzEqdwmOxNChm8UwpuiZlyNQz3KzFgZOvxXiqnq6iKgVQrKh/V4d4mroqojVu2i19e3CAfbgwom4uosHsD4uMZlqJ5Z7/LI/ZymVOphzR1tgBAhA25dlxa0gJOMEKfYjFUG7SFMVKWJfzKdL2g2UsjzRUWBxHdnyFyt3hMXThLsAF+gBv5KqMjVXfXxfqEVeiDE6xijRzZ42keKc/JPRU5bmiVcVTxrwlMnMXbT02EM9twB/yrlBcPHvxdw== root@localhost.localdomain' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

#curl -k 'http://192.168.11.3/api/duty/duty_pool.php?key=logapp&type=2'

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

%end
