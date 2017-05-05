#!/bin/bash
##################################################
#Name:        salt_rpm.sh
#Version:     v1.0
#Create_Date：2017-4-4
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "RPM方式安装salt脚本"
##################################################
AppName=salt
MASTERIP=10.10.10.10
fmaster()
{
    yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm
    yum -y install salt-master salt-minion
    cp /etc/salt/minion{,.bak}
    cp /etc/salt/master{,.bak}
    sed -i "/#master:/cmaster: $MASTERIP" /etc/salt/minion
    sed -i "/#id/cid: `hostname`" /etc/salt/minion
    sed -i "/^#pillar_opts: False/cpillar_opts: True" /etc/salt/master
    systemctl enable salt-master.service
    systemctl enable salt-minion.service
    systemctl start salt-master.service
    systemctl start salt-minion.service
}

fminion()
{
    yum -y install https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm
    yum -y install salt-minion
    cp /etc/salt/minion{,.bak}
    sed -i "/#master:/cmaster: $MASTERIP" /etc/salt/minion
    sed -i "/#id/cid: `hostname`" /etc/salt/minion
    systemctl enable salt-minion.service
    systemctl start salt-minion.service
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "master"  ) fmaster;;
    "minion"  ) fminion;;
    *         )
    echo "$ScriptFile master              安装 $AppName-master"
    echo "$ScriptFile minion              安装 $AppName-minion"
    ;;
esac
