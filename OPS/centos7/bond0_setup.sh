#!/bin/bash
##################################################
#Name:        bond0_setup.sh
#Version:     v1.0
#Create_Date：2017-4-1
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Centos7上Bond0链路接口设置"
##################################################

IP=172.16.1.20
GATEWAY=172.16.1.2
ETH0=eth0
ETH1=eth1  
ETH2=eth2  
ETH3=eth3 
#修改网卡配置文件
feth0(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH0 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-$ETH0{,.bak}
    echo "TYPE=Ethernet  
BOOTPROTO=none  
DEVICE=$ETH0  
ONBOOT=yes  
MASTER=bond0  
SLAVE=yes" > /etc/sysconfig/network-scripts/ifcfg-$ETH0 
else
   echo "ifcfg-$ETH0网卡不存在"
fi
}

feth1(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH1 ];then 
    cp  /etc/sysconfig/network-scripts/ifcfg-$ETH1{,.bak} 
    echo "TYPE=Ethernet  
BOOTPROTO=none  
DEVICE=$ETH1  
ONBOOT=yes  
MASTER=bond0  
SLAVE=yes" > /etc/sysconfig/network-scripts/ifcfg-$ETH1 
else
   echo "ifcfg-$ETH1网卡不存在"
fi
}

feth2(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH2 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-$ETH2{,.bak} 
echo "TYPE=Ethernet  
BOOTPROTO=none  
DEVICE=$ETH2  
ONBOOT=yes  
MASTER=bond1  
SLAVE=yes"> /etc/sysconfig/network-scripts/ifcfg-$ETH2  
else
   echo "ifcfg-$ETH2网卡不存在"
fi

}
  
feth3(){
if [ -f /etc/sysconfig/network-scripts/ifcfg-$ETH3 ];then 
    cp /etc/sysconfig/network-scripts/ifcfg-$ETH3{,.bak}
echo "TYPE=Ethernet  
BOOTPROTO=none  
DEVICE=$ETH3  
ONBOOT=yes  
MASTER=bond1  
SLAVE=yes" > /etc/sysconfig/network-scripts/ifcfg-$ETH3 
else
   echo "ifcfg-$ETH3网卡不存在"
fi
}

#编辑内核信息
fgrub()
{
    if [ -f etc/sysconfig/grub.bak ];then
    	echo "内核信息已编辑"
    else
    	mv /etc/sysconfig/grub{,.bak}
    	echo 'GRUB_TIMEOUT=5
    	GRUB_DEFAULT=saved
    	GRUB_DISABLE_SUBMENU=true
    	GRUB_TERMINAL_OUTPUT="console"
    	GRUB_CMDLINE_LINUX="crashkernel=auto rhgb net.ifnames=0 biosdevname=0 quiet"
    	GRUB_DISABLE_RECOVERY="true"'   >  /etc/sysconfig/grub
    	grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
}
#修改bond配置文件
fbond0()
{
echo "DEVICE=bond0  
TYPE=Bond  
NAME=bond0  
BONDING_MASTER=yes  
BOOTPROTO=static  
USERCTL=no  
ONBOOT=yes  
IPADDR=$IP  
PREFIX=24  
GATEWAY=$GATEWAY  
BONDING_OPTS="mode=1 miimon=100" "> /etc/sysconfig/network-scripts/ifcfg-bond0
} 

fbond1(){
echo "DEVICE=bond1  
TYPE=Bond  
NAME=bond1  
BONDING_MASTER=yes  
USERCTL=no  
BOOTPROTO=none  
ONBOOT=yes  
BONDING_OPTS="mode=1 miimon=100" " >  /etc/sysconfig/network-scripts/ifcfg-bond1  
}

#设置bond
fsetbond0(){
	modprobe bonding
	if [ $( grep "ifenslave bond0 eth0 eth1" /etc/rc.local | wc -l) -eq 0 ];then
		echo "ifenslave bond0 eth0 eth1" >> /etc/rc.local
	else
		echo "bond1模式已设置"
	fi
	fgrub && fbon0 && feth0 && feth1 && systemctl restart network  
	ping $GATEWAY -c 1 
	#reboot	
}

fsetbond1(){
	modprobe bonding
	if [ $( grep "ifenslave bond1 eth2 eth3" /etc/rc.local | wc -l) -eq 0 ];then
		echo "ifenslave bond1 eth2 eth3" >> /etc/rc.local
	else
		echo "bond1模式已设置"
	fi
	fgrub && fbond1 && feth2 && feth3 && systemctl restart network  
	ping $GATEWAY -c 1 
	#reboot	
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
	"bond0"  ) fbond0;;
	"bond1"  ) fbond1;;
	"eth0"   ) feth0;;
	"eth1"   ) feth1;;
	"eth2"   ) feth2;;
	"eth3"   ) feth3;;
	"setbond0" ) fsetbond0;;
	"setbond1" ) fsetbond1;;
	*		)
	echo "$ScriptFile bond0             配置文件bond0"
	echo "$ScriptFile bond1             配置文件bond1"
	echo "$ScriptFile eth0              配置文件$ETH0"
	echo "$ScriptFile eth1              配置文件$ETH1"
	echo "$ScriptFile eth2              配置文件$ETH2"
	echo "$ScriptFile eth3              配置文件$ETH3"
	echo "$ScriptFile setbond0          设置bond0"
	echo "$ScriptFile setbond1          设置bond1"
    ;;
esac
