#!/bin/bash
##########################################################################
#Name:        etcd.sh
#Version:     v3.1.5
#Create_Date: 2017-4-19
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "编译安装管理etcd"
##########################################################################

App=etcd-v3.1.5-linux-amd64
AppName=etcd
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$App
AppConfDir=/App/conf/OPS/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.tar.*$//' -e 's/^.\///')
AppProg=$AppOptDir/etcd
AppProgCtl=$AppOptDir/etcdctl
#EtcdServerIp=10.10.10.10
AppDataDir=/App/data/OPS/$AppName
EtcdServerIp=$(/usr/sbin/ifconfig eth1 | grep "inet" |  grep -v "inet6" | awk -F' ' '{print $2}')
RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
 {
	AppMasterPid=$(ps ax | grep  "${AppName}" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
}

# 查询状态
fstatus()
{
    fpid

    if [ ! -f "$AppProg" ]; then
        echo "$AppName 未安装"
    else
        echo "$AppName 已安装"
        if [ -z "$AppMasterPid" ]; then
            echo "$AppName 未启动"
        else
            echo "$AppName 正在运行"
        fi
    fi
}

# 删除
fremove()
{
    fpid
    RemoveFlag=1
    if [ -z "$AppMasterPid" ]; then
        if [ -d "$AppInstallDir" ]; then
            rm -rf $AppInstallDir && echo "删除 $AppName"
            rm -f $AppConfDir
            rm -f $AppOptDir
            rm -f $AppLogDir
        else
            echo "$AppName 未安装"
        fi
    else
        echo "$AppName 正在运行" && exit
    fi
}

# 备份
fbackup()
{
    Day=$(date +%Y-%m-%d)
    BackupFile=$App.$Day.tgz
    if [ -f "$AppProg" ]; then
        cd $AppInstallBase
        tar zcvf $BackupFile --exclude=logs/* $App/* --backup=numbered
        [ $? -eq 0 ] && echo "$AppName 备份成功" || echo "$AppName 备份失败"
    else
        echo "$AppName 未安装" 
    fi
}

# 安装
finstall()
{
    fpid
    InstallFlag=1
    if [ -z "$AppMasterPid" ]; then
        test -f "$AppProg" && echo "$AppName 已安装" 
        [ $? -ne 0 ] && fupdate && fsymlink && fcpconf
    else
        echo "$AppName 正在运行"
    fi
}

# 拷贝配置
fcpconf()
{
	/usr/bin/cp $AppInstallDir/{etcd,etcdctl}  /usr/sbin/
	chmod +x /usr/sbin/{etcd,etcdctl}
}

# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup

    test -d "$AppBuildDir" && rm -rf $AppBuildDir

    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    /usr/bin/cp -rf $AppBuildDir $AppInstallBase

    if [ $? -eq 0 ]; then
        echo "$AppName $Operate成功"
    else
        echo "$AppName $Operate失败"
        exit 1
    fi
}

#创建软连接
fsymlink()
{
    [ -L $AppOptDir ] && rm -f $AppOptDir
    [ -L $AppConfDir ] && rm -f $AppConfDir
    [ -L $AppLogDir ] && rm -f $AppLogDir
    ln -s $AppInstallDir        $AppOptDir

}

# 启动
fstart()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
    #/usr/bin/nohup ${AppProg} --name auto_scale --data-dir ${AppDataDir}  --listen-peer-urls "http://10.10.10.10:2380,http://10.10.10.10:7001" --listen-client-urls "http://10.10.10.10:2379,http://10.10.10.10:4001" --advertise-client-urls "http://10.10.10.10:2379,http://10.10.10.10:4001" &		
    /usr/bin/nohup ${AppProg} --name auto_scale --data-dir ${AppDataDir}  --listen-peer-urls "http://${EtcdServerIp}:2380,http://${EtcdServerIp}:7001" --listen-client-urls "http://${EtcdServerIp}:2379,http://${EtcdServerIp}:4001" --advertise-client-urls "http://${EtcdServerIp}:2379,http://${EtcdServerIp}:4001" &		
		sleep 0.1
        if [ -n "$(ps ax | grep "$AppName" | grep -v "grep" | awk '{print $1}' 2> /dev/null)" ]; then
           echo "$AppName 启动成功" 
        else
           echo "$AppName 启动失败"
        fi
    fi
} 

# 停止
fstop()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
		kill -9 $AppMasterPid  &>/dev/null && echo "停止 $AppName" || echo "$AppName 停止失败"
    else
        echo "$AppName 未启动"
    fi
}

# 重启
frestart()
{
    fpid
    [ -n "$AppMasterPid" ] && fstop && sleep 1
    fstart
}

# 终止进程
fkill()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        echo "$AppMasterPid" | xargs kill -9
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 主进程"
        else
            echo "终止 $AppName 主进程失败"
        fi
    else
        echo "$AppName 主进程未运行"
    fi
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) finstall;;
    "update"    ) fupdate;;
    "reinstall" ) fremove && finstall;;
    "remove"    ) fremove;;
    "backup"    ) fbackup;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "restart"   ) frestart;;
    "status"    ) fstatus;;
    "kill"      ) fkill;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile backup               备份 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile status               查询 $AppName 状态"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    ;;
esac
