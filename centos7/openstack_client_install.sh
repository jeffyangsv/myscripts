#!/bin/bash
DNSIP=192.168.4.71
yum install -y openstack-packstack
#生成应答文件
cd /root
packstack --gen-answer-file  /root/answer.txt
sed -i '/^CONFIG_KEYSTONE_ADMIN_PW/cCONFIG_KEYSTONE_ADMIN_PW=123456'  /root/answer.txt
sed -i "/^CONFIG_NTP_SERVERS/cCONFIG_NTP_SERVERS='${DNSIP}' "  /root/answer.txt
sed -i '/^CONFIG_HORIZON_SSL/cCONFIG_HORIZON_SSL=y'   /root/answer.txt
sed -i '/^CONFIG_PROVISION_DEMO/cCONFIG_PROVISION_DEMO=n'  /root/answer.txt
#安装openstack
#删除与openstack冲突的文件
rpm -e --nodeps mariadb
rpm -e --nodeps mariadb-server
rpm -e --nodeps mariadb-libs

packstack --answer-file answer.txt
#配置ovs
echo '
TYPE=OVSPort
NAME=eth0
ONBOOT=yes
DEVICETYPE=ovs
DEVICE=eth0
OVS_BRIDGE=br-ex' > /etc/sysconfig/network-scripts/ifcfg-eth0

echo '
TYPE=OVSBridge
BOOTPROTO=none
DEVICE=br-ex
ONBOOT=yes
IPADDR0=192.168.4.2
PREFIX0=24
DNS1=192.168.4.1
DEVICETYPE=ovs' > /etc/sysconfig/network-scripts/ifcfg-br-ex

ovs-vsctl add-port br-ex eth0
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart network
