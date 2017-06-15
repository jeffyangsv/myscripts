#!/usr/bin/env bash    
##################################################
#Name:        docker_ops.sh
#Version:     v0.0.1
#Create_Date: 2017-6-15
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "docker基本操作"
##################################################

#指定容器IP配置
fsetip_container(){
if [ `id -u` -ne 0 ];then
    echo '必须使用root权限'  
    exit  
fi  
  
if [ $# != 2 ]; then  
    echo "使用方法: $0 容器名字 IP"  
    exit 1  
fi  
  
container_name=$1  
bind_ip=$2  
  
container_id=`docker inspect -f '{{.Id}}' $container_name 2> /dev/null`  
if [ ! $container_id ];then  
    echo "容器不存在"  
    exit 2  
fi  
bind_ip=`echo $bind_ip | egrep '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'`  
if [ ! $bind_ip ];then  
    echo "IP地址格式不正确"  
    exit 3  
fi  
  
container_minid=`echo $container_id | cut -c 1-10`  
container_netmask=`ip addr show docker0 | grep "inet\b" | awk '{print $2}' | cut -d / -f2`  
container_gw=`ip addr show docker0 | grep "inet\b" | awk '{print $2}' | cut -d / -f1`  
  
bridge_name="veth_$container_minid"  
container_ip=$bind_ip/$container_netmask  
pid=`docker inspect -f '{{.State.Pid}}' $container_name 2> /dev/null`  
if [ ! $pid ];then  
    echo "获取容器$container_name的id失败"  
    exit 4  
fi  
  
if [ ! -d /var/run/netns ];then  
    mkdir -p /var/run/netns  
fi  
  
ln -sf /proc/$pid/ns/net /var/run/netns/$pid  
  
ip link add $bridge_name type veth peer name X  
brctl addif docker0 $bridge_name  
ip link set $bridge_name up  
ip link set X netns $pid  
ip netns exec $pid ip link set dev X name eth0  
ip netns exec $pid ip link set eth0 up  
ip netns exec $pid ip addr add $container_ip dev eth0  
ip netns exec $pid ip route add default via $container_gw
echo "指定容器IP配置成功"
}

#进入容器
fdocker_enter(){
CNAME=$1
CPID=$(docker inspect --format "{{.State.Pid}}" $CNAME)
echo "容器${CNAME}的pid是${CPID}"
nsenter --target "$CPID" --uts --ipc --net --pid
}

#查看容器运行状态
fallstatus(){
	docker ps -a
	}

#启动容器
fstart(){
CNAME=$1
docker start $CNAME	
}

#停止容器
fstop(){
CNAME=$1
docker stop $CNAME	
}

#重启容器
frestart(){
CNAME=$1
docker restart $CNAME	
}

#删除容器
fdelete(){
CNAME=$1
docker rm $CNAME	
}

#启动所有容器
fallstart(){
CNAME=$(docker ps -a | grep -v 'CONTAINER'|awk '{print $1}')
docker start $CNAME 	
}

#停止所有容器
fallstop(){
CNAME=$(docker ps -a | grep -v 'CONTAINER'|awk '{print $1}')
docker stop $CNAME 	
}
#重启所有容器
fallrestart(){
CNAME=$(docker ps -a | grep -v 'CONTAINER'|awk '{print $1}')
docker restart $CNAME	
}

#删除所有容器
falldelete(){
CNAME=$(docker ps -a | grep -v 'CONTAINER'|awk '{print $1}')
docker rm $CNAME	
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "setip"   		)	fsetip_container $2 $3;;
    "enter"   		) 	fdocker_enter $2;;
    "ps"   			) 	fallstatus;;
    "start"  		) 	fstart $2;;
    "stop"    		) 	fstop $2;;
    "restart"		) 	frestart $2;;
    "rm"      	 	) 	fdelete $2;;
    "allstart"  	) 	fallstart ;;
    "allstop"    	) 	fallstop;;
    "allrestart" 	) 	fallrestart $2;;
    "allrm"      	) 	falldelete $2;;
    *            	)
    echo "$ScriptFile setip             指定容器IP   $AppName"
    echo "$ScriptFile enter             进入容器 	 $AppName"
    echo "$ScriptFile ps                查看状态 	 $AppName"
    echo "$ScriptFile start             启动容器 	 $AppName"
    echo "$ScriptFile stop              停止容器 	 $AppName"
    echo "$ScriptFile restart           重启容器 	 $AppName"
    echo "$ScriptFile rm                删除容器 	 $AppName"
    echo "$ScriptFile allstart          启动所有容器 $AppName"
    echo "$ScriptFile allstop           停止所有容器 $AppName"
    echo "$ScriptFile allrestart        重启所有容器 $AppName"
    echo "$ScriptFile allrm             删除所有容器 $AppName"
    ;;
esac
