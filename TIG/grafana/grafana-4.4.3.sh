#/bin/bash
#------------------------------------------------
#Name:        grafana-4.4.3.sh
#Version:     v4.4.3
#Create_Date: 2017-8-16
#Author:      GuoLikai
#Description: "Grafana一键部署启动脚本"
#------------------------------------------------

App=grafana-4.4.3
AppName=grafana
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$App
AppConfBase=/App/conf/OPS
AppConfDir=$AppConfBase/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=${App}.linux-x64.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.linux.*$//' -e 's/^.\///')
AppProg=$AppOptDir/bin/grafana-server
AppProgCli=$AppOptDir/bin/grafana-cli
AppConf=$AppLogDir/$AppName.ini

AppDataDir=/App/data/OPS/$AppName
AppPluginsDir=$AppDataDir/plugins
AppPidFile=$AppLogDir/$AppName.pid

MysqlIp=localhost
MysqlUser=root
MysqlPass=123456
MysqlProg=/usr/bin/mysql
MysqlSock=/var/lib/mysql/mysql.sock

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

    Day=$(date +%Y-%m-%d)
    BackupFile=$AppName.$Day.bak
    if [ -f "$AppConfDir/$AppConfName" ]; then
    	mv $AppConfDir/$AppConfName $AppConfBase/$BackupFile
    #    [ $? -eq 0 ] && echo "$AppConfName 删除时备份配置文件成功" || echo "$AppConfName 删除时备份配置文件失败"
    fi

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
    useradd -s /sbin/nologin grafana
    mkdir -p $AppPluginsDir
    mkdir -p $AppLogDir
    mkdir -p $AppDataDir/dashboards
    chown -R grafana:grafana $AppPluginsDir
    chown -R grafana:grafana $AppLogDir

    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    cp -rp $AppBuildDir $AppInstallDir
    #cp $AppInstallDir/conf/defaults.ini  $AppInstallDir/conf/${AppName}.ini
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
    ln -s $AppInstallDir $AppOptDir
    ln -s $AppInstallDir/conf $AppConfDir
}

# 拷贝配置
fcpconf()
{ 
    cp  $AppConfDir/defaults.ini  $AppConfDir/${AppName}.ini
    sed -i "/^logs/clogs = $AppLogDir"                   $AppConfDir/${AppName}.ini
    sed -i "/^data = data/cdata = $AppDataDir"           $AppConfDir/${AppName}.ini
    sed -i "/^plugins/cplugins = $AppPluginsDir"         $AppConfDir/${AppName}.ini
    sed -i '/\[dashboards.json\]/{n;s#false#true#}'      $AppConfDir/${AppName}.ini
    sed -i "/\[dashboards.json\]/{n;n;s#/var/lib/grafana#$AppDataDir#}"  $AppConfDir/${AppName}.ini
}
#修改数据库相关配置

fmysqlconf(){
    if [ $(grep "type = mysql" $AppConfDir/${AppName}.ini | wc -l) -eq 0 ];then
       sed -i '/^type = sqlite3/ctype = mysql'                           $AppConfDir/${AppName}.ini
       sed -i "/^host = 127.0.0.1:3306/chost =$MysqlIp:3306"             $AppConfDir/${AppName}.ini
       sed -i '/^name = grafana/cname = grafana'                         $AppConfDir/${AppName}.ini
       sed -i '/^user = root/cuser = grafana'                            $AppConfDir/${AppName}.ini
       sed -i '/^password =/cpassword = grafana'                         $AppConfDir/${AppName}.ini
    else 
       echo "$AppName 配置文件已修改" 
   fi 
}

# 配置MySQL数据库存储
fmysqld()
{
    MysqlPid=$(ps ax | grep -w "mysqld" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    MysqlConn="$MysqlProg -h$MysqlIp -u$MysqlUser -p$MysqlPass -S $MysqlSock"
    if [ -n "MysqlPid" ];then 
      if [ $($MysqlConn -e "show databases" | grep -w "grafana" | wc -l) -eq 0 ];then
        $MysqlConn -e "create database if not exists $AppName default character set utf8;" && \
        $MysqlConn -e "grant all on $AppName.* to '$AppName'@'$MysqlIp' identified by '$AppName';"  &&  \
        $MysqlConn -e "grant all on $AppName.* to '$AppName'@'%' identified by '$AppName';" && \
        $MysqlConn -e "flush privileges"  && echo "$AppName 数据库创建授权成功"  && fmysqlconf
      else 
        echo "$AppName 数据库已存在"  && fmysqlconf 
      fi
    else
        echo "mysql 数据库未启动" 
    fi
}

# 启动
fstart()
{
    fpid
    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
        #$AppProg -config=$AppConfDir/${AppName}.ini -homepath=$AppInstallDir 
        $AppProg -config=$AppConfDir/${AppName}.ini -homepath=$AppOptDir -pidfile=$AppPidFile  cfg:default.paths.logs=$AppLogDir cfg:default.paths.data=$AppDataDir cfg:default.paths.plugins=$AppPluginsDir &>/dev/null &
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

# 插件安装
fcli(){
    fpid
    if [ $# -eq 1 ];then
        Name=$1
    else
        echo "USAGE: $0 cli PluginName"
        exit 1    
    fi
    if [ -n "$AppMasterPid" ]; then
        #grafana-cli plugins install  $(grafana-cli plugins list-remote | grep zabbix | awk '{print $2}')
        #查看插件命令 $AppProgCli plugins list-remote 
        PluginName=`$AppProgCli plugins list-remote | grep "${Name}"| awk '{print $2}'`
        if [ $PluginName ];then
            $AppProgCli plugins install  $PluginName &>/dev/null  && [ $? -eq 0 ]  && mv /var/lib/grafana/plugins/$PluginName $AppPluginsDir/ &>/dev/null  && echo "$AppName $PluginName 插件下载成功" && frestart &>/dev/null || echo "$AppName $PluginName 插件已存在" && rm -rf /var/lib/grafana/plugins/$PluginName
        else
            echo "【$AppName】不支持【${Name}】插件,支持的插件有:"
            $AppProgCli plugins list-remote 
        fi
    else
        echo "$AppName 未启动"
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
    "mysqld"    ) fmysqld;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "status"    ) fstatus;;
    "restart"   ) frestart;;
    "kill"      ) fkill;;
    "cli"       ) fcli $2;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile backup               备份 $AppName"
    echo "$ScriptFile mysqld               配置 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile status               状态 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile cli PluginName       安装 $AppName 插件"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    ;;
esac
