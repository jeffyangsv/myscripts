#!/bin/sh
##################################################
#Name:        Python-3.5.2
#Version:     v3.5.2
#Create_Date: 2017-5-17
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "编译安装管理Python3"
##################################################

App=Python-3.5.2
AppName=python3
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/usr/local
AppInstallDir=$AppInstallBase/$AppName
AppConfDir=/App/conf/OPS/$AppName
AppLogDir=/App/log/OPS/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tgz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.tgz.*$//' -e 's/^.\///')

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "python3" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
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
			rm -rf /usr/bin/python3
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
# 安装依赖
finsdep()
{
    yum install openssl-devel bzip2-devel expat-devel gdbm-devel readline-devel sqlite-devel -y
}


# 安装
finstall()
{

    fpid
    InstallFlag=1

    if [ -z "$AppMasterPid" ]; then
        test -f "$AppProg" && echo "$AppName 已安装" 
        [ $? -ne 0 ] && finsdep && fupdate && fsymlink
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
    #wget -O $AppSrcBase/Python-3.5.2.tgz  https://www.python.org/ftp/python/3.5.1/Python-3.5.2.tgz
    test -d "$AppBuildDir" && rm -rf $AppBuildDir
    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    /usr/bin/cp -rp $AppBuildDir $AppInstallDir
	#rm -rf /usr/bin/python   #删除Python2
	cd $AppInstallDir && ./configure --with-zlib --enable-shared --enable-loadable-sqlite-extensions &&  make && make install
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
	
	ln -s /usr/local/bin/python3.5 /usr/bin/python3
    ln -s $AppInstallDir  $AppOptDir
	echo "/usr/local/lib" >> /etc/ld.so.conf && /sbin/ldconfig && /sbin/ldconfig -v
	python3 -V
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) finstall;;
    "update"    ) fupdate;;
    "reinstall" ) fremove && finstall;;
    "remove"    ) fremove;;
    "backup"    ) fbackup;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    ;;
esac
