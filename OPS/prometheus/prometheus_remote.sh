#/bin/bash
##################################################
#Name:        prometheus_remote.sh
#Version:     v1.5.2
#Create_Date: 2017-3-1
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Prometheus源码Go语言编写,可直接启动"
##################################################

App=prometheus-1.5.2.linux-amd64
AppName=prometheus
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$AppName
AppConfDir=/App/conf/OPS/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.linux.*$//' -e 's/^.\///')
AppProg=$AppInstallDir/$AppName
AppConf=$AppInstallDir/$AppName.yml

InfluxdbHost=172.16.1.100
InfluxdbUser=admin
InfluxdbPass=admin 


RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "prometheus" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
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

    #Day=$(date +%Y-%m-%d)
    #BackupFile=$AppName.$Day.yml.bak
    #if [ -f "$AppConfDir/$AppConfName" ]; then
    #	mv $AppConfDir/$AppConfName /App/conf/OPS/$BackupFile
    #   [ $? -eq 0 ] && echo "$AppConfName 删除时备份配置文件成功" || echo "$AppConfName 删除时备份配置文件失败"
    #fi

    if [ -z "$AppMasterPid" ]; then
        if [ -d "$AppInstallDir" ]; then
            rm -rf $AppInstallDir && echo "删除 $AppName"
            rm -rf $AppConfDir
            rm -rf $AppOptDir
            rm -rf $AppLogDir
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
    BackupFile=$AppName.$Day.tgz

    if [ -f "$AppProg" ]; then
        cd $AppInstallBase
        tar zcvf $BackupFile --exclude=logs/* $AppName/* --backup=numbered
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

# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup

    test -d "$AppBuildDir" && rm -rf $AppBuildDir
    #tar zxvf /App/src/OPS/prometheus-1.5.2.linux-amd64.tar.gz -C /App/build/OPS/prometheus --strip-components=1
    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    cp -rp $AppBuildBase/$App $AppInstallDir
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

# 拷贝配置
fcpconf()
{ 
    mkdir $AppConfDir   &>/dev/null
    ln -s  $AppConf $AppConfDir/  &>/dev/null
}

fdatabase()
{
    InfluxdbPid=$(ps ax | grep "influxd" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    InfluxConn="influx -host $InfluxdbHost -username $InfluxdbUser -password $InfluxdbUser"
    if [ -n "$InfluxdbPid" ];then 
	Result=$($InfluxConn -execute "show databases" | grep -w "prometheus" | wc -l)
	if [ $Result -eq 0 ];then
 	    $InfluxConn -execute "create database $AppName" 
            $InfluxConn -execute "create user "$AppName" with password '$AppName'" 
            $InfluxConn -execute "GRANT ALL ON $AppName TO $AppName" && echo "$AppName 数据库创建授权成功"
	#influx -host localhost -username prometheus -password prometheus  -database prometheus  #访问数据库命令
	else 
	    echo "$AppName 数据库已存在" 
	fi
    else
        echo "Influxdb 数据库未启动" 
    fi

}

# 启动
fstart()
{
    #/App/install/OPS/prometheus/prometheus -config.file=prometheus.yml
    fpid
    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
        #App/install/OPS/prometheus/prometheus  -config.file=/App/conf/OPS/prometheus/prometheus.yml -web.console.libraries=/App/conf/OPS/prometheus/console_libraries -web.console.templates=/App/conf/OPS/prometheusconsoles -storage.remote.influxdb-url='http://172.16.1.20:8086' -storage.remote.influxdb.database=prometheus -storage.remote.influxdb.retention-policy=autogen -storage.remote.influxdb.username=prometheus
        export INFLUXDB_PW=$AppName
	$AppProg -config.file=$AppConfDir/${AppName}.yml \
		 -storage.local.path=$AppInstallDir/data \
                 -web.console.libraries=$AppInstallDir/console_libraries \
                 -web.console.templates=$AppInstallDir/consoles \
		 -storage.remote.influxdb-url="http://${InfluxdbHost}:8086" \
		 -storage.remote.influxdb.database=$AppName \
		 -storage.remote.influxdb.retention-policy=autogen \
		 -storage.remote.influxdb.username=$AppName  &>/dev/null &
        sleep 0.5
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

# 终止进程
fkill()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        echo "$AppMasterPid" | xargs kill -9 &>/dev/null
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 主进程"
        else
            echo "终止 $AppName 主进程失败"
        fi
    else
        echo "$AppName 主进程未运行"
    fi
}

# 重启
frestart()
{
    fpid
    [ -n "$AppMasterPid" ] && fstop && sleep 1
    fstart
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) finstall;;
    "update"    ) fupdate;;
    "reinstall" ) fremove && finstall;;
    "remove"    ) fremove;;
    "backup"    ) fbackup;;
    "database"  ) fdatabase;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "status"    ) fstatus;;
    "restart"   ) frestart;;
    "kill"      ) fkill;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile backup               备份 $AppName"
    echo "$ScriptFile database             数据 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile status               状态 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    ;;
esac
