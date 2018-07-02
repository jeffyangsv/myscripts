#!/bin/sh
#-------------------------------------------------
#Name:        Python-3.6.5
#Version:     v3.6.5
#Create_Date: 2018-7-2
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "编译安装管理Python3"
#-------------------------------------------------
App=Python-3.6.5
AppName=python3
AppInstallBase=/usr/local
AppInstallDir=${AppInstallBase}/${AppName}
AppSrcBase=/opt/soft
AppTarBall=${App}.tgz
AppBuildBase=/opt/soft/build
AppBuildDir=$(echo "${AppBuildBase}/${AppTarBall}" | sed -e 's/.tgz.*$//' -e 's/^.\///')

AppProg=/usr/bin/python3

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

    if [ ! -f "${AppProg}" ]; then
        echo "${AppName} 未安装"
    else
        echo "${AppName} 已安装"
        if [ -z "${AppMasterPid}" ]; then
            echo "${AppName} 未启动"
        else
            echo "${AppName} 正在运行"
        fi
    fi
}

# 删除
fremove()
{
    fpid
    RemoveFlag=1

    if [ -z "${AppMasterPid}" ]; then
        if [ -d "${AppInstallDir}" ]; then
            rm -rf ${AppInstallDir} && echo "删除 ${AppName}"
            rm -rf /usr/bin/python3
        else
            echo "${AppName} 未安装"
        fi
    else
        echo "${AppName} 正在运行" && exit
    fi
}

# 备份
fbackup()
{
    Day=$(date +%Y-%m-%d)
    BackupFile=${AppName}.${Day}.tgz

    if [ -f "${AppProg}" ]; then
        cd ${AppInstallBase}
        tar zcvf ${BackupFile} --exclude=logs/* ${AppName}/* --backup=numbered
        [ $? -eq 0 ] && echo "${AppName} 备份成功" || echo "${AppName} 备份失败"
    else
        echo "${AppName} 未安装" 
    fi
}
# 安装依赖
finsdep()
{
    yum install gcc-c++  openssl-devel bzip2-devel expat-devel gdbm-devel readline-devel sqlite-devel tcl-devel tk-devel tkinter  -y
}


# 安装
finstall()
{

    fpid
    InstallFlag=1

    if [ -z "${AppMasterPid}" ]; then
        test -f "${AppProg}" && echo "${AppName} 已安装" 
        [ $? -ne 0 ] && finsdep && fupdate && fsymlink
    else
        echo "${AppName} 正在运行"
    fi
}

# 更新
fupdate()
{
    Operate="更新"
    [ ${InstallFlag} -eq 1 ] && Operate="安装"
    [ ${RemoveFlag} -ne 1 ]  && fbackup
    test -f ${AppSrcBase}/${AppTarBall} && echo "${AppSrcBase}/${AppTarBall}已存在"|| wget -O ${AppSrcBase}/Python-3.6.5.tgz  https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz
    test -d "${AppBuildDir}" && rm -rf ${AppBuildDir}
    tar zxf ${AppSrcBase}/${AppTarBall} -C ${AppBuildBase} || tar jxf ${AppSrcBase}/${AppTarBall} -C ${AppBuildBase}
    #rm -rf /usr/bin/python   #删除Python2
    cd ${AppBuildDir} && ./configure  --prefix=${AppInstallDir}  --enable-shared --enable-loadable-sqlite-extensions &&  make && make install
    if [ $? -eq 0 ]; then
        echo "${AppName} ${Operate}成功"
    else
        echo "${AppName} ${Operate}失败"
        exit 1
    fi
}

#创建软连接
fsymlink()
{
    ln -s ${AppInstallDir}/bin/python3.6 /usr/bin/python3
    echo "${AppInstallDir}/lib" >> /etc/ld.so.conf && /sbin/ldconfig && /sbin/ldconfig -v
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
    echo "${ScriptFile} install              安装 ${AppName}"
    echo "${ScriptFile} update               更新 ${AppName}"
    echo "${ScriptFile} reinstall            重装 ${AppName}"
    echo "${ScriptFile} remove               删除 ${AppName}"
    ;;
esac
