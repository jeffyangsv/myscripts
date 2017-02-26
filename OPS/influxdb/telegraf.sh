#/bin/bash
##########################################################################
#Name:        telegraf.sh
#Version:     v1.2.1
#Create_Date: 2017-2-26
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "Telegraf是Influxdata公司开发,纯go编写"
#The plugin-driven server agent for reporting metrics into InfluxDB
#用于采集系统数据(system，docker，redis，nginx，kafka等)监控指标
##########################################################################

App=telegraf-1.2.1_linux_amd64
AppName=telegraf
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$AppName
AppConfDir=/App/conf/OPS/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.1.*$//' -e 's/^.\///')
AppProg=$AppInstallDir/usr/bin/$AppName
AppConf=$AppInstallDir/etc/$AppName/$AppName.conf

AppDataBase=/App/data
AppDataDir=/App/data/OPS/$AppName

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "$AppName" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
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
    #wget -O $AppSrcBase/$AppTarBall  https://dl.influxdata.com/telegraf/releases/telegraf-1.2.1_linux_amd64.tar.gz  
    test -d "$AppBuildDir" && rm -rf $AppBuildDir
    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    cp -rp $AppBuildDir $AppInstallDir

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

    ln -s $AppInstallDir  $AppOptDir
}

# 拷贝配置
fcpconf()
{ 
    mkdir -p $AppConfDir/$AppName.d   &>/dev/null
    #/App/install/OPS/telegraf/usr/bin/telegraf -sample-config -input-filter cpu:mem -output-filter influxdb > /App/conf/OPS/telegraf/telegraf.conf
    $AppProg -sample-config -input-filter cpu:mem -output-filter influxdb > $AppConfDir/$AppName.conf
}

fdatabase()
{
    InfluxdbPid=$(ps ax | grep "influxd" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    AdminUser=admin
    AdminPass=admin 
    InfluxConn="influx -username $AdminUser -password $AdminPass"
    if [ -n "$InfluxdbPid" ];then 
	Result=$($InfluxConn -execute "show databases" | grep -w "telegraf" | wc -l)
	if [ $Result -eq 0 ];then
 	    $InfluxConn -execute "create database telegraf" 
            $InfluxConn -execute "create user "telegraf" with password 'telegraf'" 
            $InfluxConn -execute "GRANT ALL ON telegraf TO telegraf" && echo "$AppName 数据库创建授权成功"
	#influx -username telegraf -password telegraf  -database telegraf  #访问数据库命令
	else 
	    echo "$AppName 数据库已存在" 
	fi
    else
        echo "Influxdb 数据库未启动" 
    fi

}

# 修改配置
fsetconf()
{
    DockerIpPort=192.168.30.191:8080
    RedisIpPort=172.16.1.20:6379
    InfluxdbIp=172.16.1.20
    Result=$(grep "inputs.disk" $AppConfDir/$AppName.conf | wc -l) 	 
    if [ $Result -eq 0 ];then
        sed -i '/^  # dc/s/\#.*/dc = "docker-test"/'	    	$AppConfDir/$AppName.conf
        sed -i '/^  # username = "telegraf"/s/# //'  	    	$AppConfDir/$AppName.conf
        sed -i '/^  # password/s/\#.*/password = "telegraf"/'   $AppConfDir/$AppName.conf
        sed -i "/^  urls = \[/s/localhost/${InfluxdbIp}/"	$AppConfDir/$AppName.conf
        echo '[[inputs.disk]]
#默认的telegraf将手机所有挂载点的信息
#下面这个参数可以指定挂载点
  mount_points = ["/"]
#仅存储磁盘inode相关的度量值
  fieldpass = ["inodes*"]
#通过文件系统类型来忽略一些挂载点，比如tmpfs
  ignore_fs = ["tmpfs", "devtmpfs"]
#仅存储tagpass相关的信息
[inputs.disk.tagpass]
  fstype = [ "ext4", "xfs" ]
  path = [ "/export", "/home*" ]
#默认telegraf将采集所有存储设备的信息，devices参数可以指定
# devices = ["sda", "sdb"]
#如果需要磁盘的串行号可以将下面注释打开
# skip_serial_number = false
#[[inputs.mem]]
#采集docker和redis的插件
[[inputs.docker]]
#指定docker启动的api接口，并指定需要采集那些容器指标
  endpoint = "tcp://'$DockerIpPort'"
  container_names = []
[[inputs.redis]]
#指定redis的相关接口
  #servers = ["tcp://'$RedisIpPort'"] '  >>  $AppConfDir/$AppName.conf
    	else
             echo "$AppName 已配置" 
    fi
}


# 启动
fstart()
{
    fpid
    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
	#/App/install/OPS/telegraf/usr/bin/telegraf -config /App/conf/OPS/telegraf/telegraf.conf
	$AppProg -config "$AppConfDir/$AppName.conf"  -config-directory $AppConfDir/$AppName.d &>/dev/null &
	[ $? -eq 0 ] && echo "$AppName 启动成功" || echo "$AppName 启动失败"
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
    "setconf"	) fsetconf;;
    "database"	) fdatabase;;
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
    echo "$ScriptFile setconf              配置 $AppName"
    echo "$ScriptFile database             数据 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile status               状态 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile auth                 权限 $AppName"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    ;;
esac
