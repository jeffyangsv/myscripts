#/bin/bash
##################################################
#Name:        zabbix_server.sh
#Version:     v3.2.3
#Create_Date: 2017-3-3
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "zabbix_server一键部署启动脚本"
##################################################

App=zabbix-3.2.3
AppName=grafana
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$AppName
AppConfBase=/App/conf/OPS/
AppConfDir=/App/conf/OPS/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.3.*$//' -e 's/^.\///')
AppProg=$AppInstallDir/bin/grafana-server
AppProgCli=$AppInstallDir/bin/grafana-cli
AppConf=$AppInstallDir/conf/$AppName.ini

AppDataDir=/App/data/OPS/$AppName
AppPluginsDir=$AppDataDir/plugins
AppPidFile=$AppDataDir/$AppName.pid

MysqlIp=localhost
MysqlUser=root
MysqlPass=123456 
MysqlProg=/usr/bin/mysql
MysqlSock=/tmp/mysql_3306.sock

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
        [ $? -ne 0 ] &&  finsdep && fupdate && fsymlink && fcpconf 
    else
        echo "$AppName 正在运行"
    fi
}
# 安装依赖
finsdep()
{
    yum install -y gcc make autoconf gcc net-snmp-devel curl curl-devel mysql-devel net-snmp libxml2 libxml2-devel
	#fping-3.10-4.el7.x86_64.rpm
	#iksemel-1.4-6.el7.x86_64.rpm
	#php-bcmath-5.4.16-36.el7_1.x86_64.rpm
	#php-common-5.4.16-36.el7_1.x86_64.rpm
	#php-mbstring-5.4.16-36.el7_1.x86_64.rpm
	yum-config-manager --add=http://dl.fedoraproject.org/pub/epel/7/x86_64/ && echo 'gpgcheck=0' >> /etc/yum.repos.d/dl.fedoraproject.org_pub_epel_7_x86_64_.repo
    yum -y install 	fping iksemel php-bcmath php-common php-mbstring
}


# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup
    test -d "$AppBuildDir" && rm -rf $AppBuildDir
    useradd -s /sbin/nologin $AppName  &>/dev/null
    mkdir -p $AppConfDir
    mkdir -p $AppLogDir
    mkdir -p $AppDataDir/dashboards
    chown -R $AppName:$AppName $AppLogDir

    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
	cd $AppBuildDir/$App
	#./configure --prefix=$AppInstallDir --enable-agent --with-net-snmp --with-libcurl
	/bin/bash configure --prefix=$AppInstallDir --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2
	make && make install
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
	ln -s $AppInstallDir/etc
    ln -s $AppInstallDir $AppOptDir
	ln -s $AppInstallDir/sbin/*  /usr/local/sbin/
	ln -s $AppInstallDir/bin/*   /usr/local/bin/
}

# 拷贝配置
fcpconf()
{ 
    ln -s $AppConf  $AppConfDir/
}

# 配置Mysql数据库存储
fdatabase()
{
    MysqlPid=$(ps ax | grep -w "mysqld" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    MysqlConn="$MysqlProg -h$MysqlIp -u$MysqlUser -p$MysqlPass -S $MysqlSock"
    if [ -n "MysqlPid" ];then 
	Result=$($MysqlConn -e "show databases" | grep -w "grafana" | wc -l)
		if [ $Result -eq 0 ];then
			$MysqlConn -e "create database if not exists $AppName default character set utf8;" && \
			$MysqlConn -e "grant all on grafana.* to '$AppName'@'$MysqlIp' identified by '$AppName';" && \
			$MysqlConn -e "grant all on grafana.* to '$AppName'@'%' identified by '$AppName';" && \
			$MysqlConn -e "flush privileges"  && echo "$AppName 数据库创建授权成功"  && \
			sed -i "s@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g" /etc/httpd/conf.d/zabbix.conf
			sed -i "s#graphfont#simkai#g" /usr/share/zabbix/include/defines.inc.php
			sed -i "/^function getLocales/{n;;n;n;n;n;s/false/true/}"  /usr/share/zabbix/include/locales.inc.php
			#修改zabbix服务器配置文件
			#sed -i "/^DBName/cDBName=$AppName"           	$AppConfDir/$AppName.conf       #设置zabbix数据库名称
			#sed -i "/^DBUser/cDBUser=$AppName"           	$AppConfDir/$AppName.conf       #设置zabbix数据库账户
			#sed -i "/^# DBPassword/cDBPassword=$AppName"   $AppConfDir/$AppName.conf       #设置zabbix数据库密码
		else 
			echo "$AppName 数据库已存在" 
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
        #$AppProg -config=$AppConfDir/$AppName.ini -homepath=$AppInstallDir 
        $AppProg -config=$AppConfDir/$AppName.ini -homepath=$AppInstallDir -pidfile=$AppPidFile  cfg:default.paths.logs=$AppLogDir cfg:default.paths.data=$AppDataDir cfg:default.paths.plugins=$AppPluginsDir &>/dev/null &
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

# 插件安装
fcli(){
    fpid
    if [ -n "$AppMasterPid" ]; then
	#grafana-cli plugins install  $(grafana-cli plugins list-remote | grep zabbix | awk '{print $2}')
        #查看插件命令 $AppProgCli plugins list-remote 
        PluginName=`$AppProgCli plugins list-remote | grep "$1"| awk '{print $2}'`
	if [ $PluginName ];then
	    $AppProgCli plugins install  $PluginName  && [ $? -eq 0 ]  && mv /var/lib/grafana/plugins/$PluginName $AppPluginsDir/ && echo "$AppName $PluginName 插件下载成功" && frestart &>/dev/null || echo "$AppName $PluginName 已存在" && rm -rf /var/lib/grafana/plugins/$PluginName 
        else
	    echo "$AppName 不支持${PluginName}插件,支持的插件有:"
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
    "database"  ) fdatabase;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "status"    ) fstatus;;
    "restart"   ) frestart;;
    "kill"      ) fkill;;
    "cli"	) fcli $2;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile backup               备份 $AppName"
    echo "$ScriptFile database             配置 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile status               状态 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile cli PluginName       安装 $AppName 插件"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    ;;
esac
