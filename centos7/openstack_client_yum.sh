#!/bin/bash
HOSTNAME=ops50.tedu.cn
IP=192.168.4.50
DNSIP=192.168.4.71
hostnamectl set-hostname $HOSTNAME
#nmcli connection add type ethernet con-name eth0 ifname eth0
#nmcli connection modify eth0 ipv4.addresses "${IP}/24 ${DNSIP}"
#nmcli connection modify eth0 ipv4.dns "${DNSIP}"
#nmcli connection modify eth0 ipv4.method manual
#nmcli connection up eth0
systemctl restart NetworkManger
systemctl enable  NetworkManger
systemctl stop   firewalld
systemctl disable firewalld
sed -i  '/^SELINUX=/cSELINUX=permissive' /etc/selinux/config 
rm  -rf  /etc/yum.repos.d/*
yum-config-manager --add http://192.168.4.254/rhel7
sed -i '$agpgcheck=0'  /etc/yum.repos.d/192.168.4.254_rhel7.repo
yum-config-manager --add http://192.168.4.254/rht
sed -i '$agpgcheck=0'  /etc/yum.repos.d/192.168.4.254_rht.repo
yum-config-manager --add http://192.168.4.254/osp5
sed -i '$agpgcheck=0'  /etc/yum.repos.d/192.168.4.254_osp5.repo
yum update -y
reboot
