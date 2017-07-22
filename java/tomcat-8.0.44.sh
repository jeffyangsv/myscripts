#!/bin/sh
##################################################
#Name:        tomcat-8.0.44.sh
#Version:     v8.0.44
#Create_Date: 2017-5-26
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "安装管理Tomcat"
##################################################

App=apache-tomcat-8.0.44
AppName=tomcat
AppOptBase=/App/opt/OPS
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$App
App_INS_BASE="$AppInstallDir/tomcat_ins"
AppConfBase=/App/conf/OPS
AppLogBase=/App/log/OPS
AppDataDir=/App/data/$AppName
AppSrcBase=/App/src/OPS
AppTarBall=$App.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.tar.*$//' -e 's/^.\///')


source /etc/profile

# 获取PID
fpid()
{
    local AppDir=$1

    AppPid=$(ps ax | grep "$AppDir/" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
}

# 查询状态
fstatus()
{
    local A_INS_NUM="$@"                                                                                                               

    for NUM in ${A_INS_NUM[@]}
    do  
        S_AppOptInsDir="$App_INS_BASE/tomcat_$NUM"
        fpid "$S_AppOptInsDir" 

        if [ ! -f "$AppStartup" ]; then
            echo "tomcat_$NUM 未安装"
        else
            echo "tomcat_$NUM 已安装"
            if [ -z "$AppPid" ]; then
                echo "tomcat_$NUM 未启动"
            else
                echo "tomcat_$NUM 正在运行"
            fi
        fi
    done
}

# 删除
fremove()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do
        S_AppOptInsDir="$App_INS_BASE/tomcat_$NUM"
        fpid "$S_AppOptInsDir"  

    done

    if [ -z "$AppPid" ]; then
        if [ -d "$AppInstallDir" ]; then
            rm -rf $AppInstallDir
            rm -f $AppConfBase/tomcat_*
            rm -f $AppOptBase/tomcat_*
            rm -f $AppLogBase/tomcat_*
            [ ! -d $AppInstallDir ] && [ ! -f $AppConfBase/tomcat_* ] && [ ! -f $AppOptBase/tomcat_* ] && [ ! -f $AppLogBase/tomcat_* ] && echo "删除 $AppName"

        else
            echo "$AppName 未安装"
        fi
    else
        echo "$AppName 正在运行" && exit 1
    fi
}

# 备份
fbackup()
{
    Day=$(date +%Y-%m-%d)
    BackupFile=tomcat_$NUM.$Day.tgz

    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        if [ -d "$AppOptBase/tomcat_$NUM" ]; then
            cd "$AppOptBase/tomcat_$NUM"
            tar zcvf $BackupFile --exclude=logs/* --exclude=work/* --exclude=temp/* --exclude=webapps/*  .
            [ $? -eq 0 ] && echo "tomcat_$NUM 备份成功" || echo "tomcat_$NUM 备份失败"
        else
            echo "tomcat_$NUM 未安装"
        fi
    done
}

# 安装
finstall()
{
    local A_INS_NUM="$@"

    [ ! -n "$A_INS_NUM" ] && echo 未指定实例个数 && exit 2

    for NUM in ${A_INS_NUM[@]}
    do  
        [ -d "$AppInstallDir/tomcat_ins/tomcat_$NUM" ] && echo "tomcat_$NUM 已安装" && exit 1
        fupdate $NUM && finit $NUM 
    done
}

# 拷贝配置
fcpconf()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        local PORT=$((8080 + $NUM))

        if [[ $PORT -ge 8080 && $PORT -le 8099 ]];then 
            #cp -vf --backup=numbered $ScriptDir/server.xml $AppInstallDir/tomcat_ins/tomcat_$NUM/conf/
            #cp -vf --backup=numbered $ScriptDir/context.xml $AppInstallDir/tomcat_ins/tomcat_$NUM/conf/
            sed -i 's/port="8080"/Port="'$PORT'"/g' $AppInstallDir/tomcat_ins/tomcat_$NUM/conf/server.xml
        else

            echo "超出端口设定范围，端口应设定在8080-8099之间,请重新设定该实例端口并执行cpconf"
        fi

    done
}

#创建软连接
fsymlink()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do 
        S_AppOptInsDir="$AppOptBase/tomcat_$NUM"
        S_AppLogInsDir="$AppLogBase/tomcat_$NUM"
        S_AppConfInsDir="$AppConfBase/tomcat_$NUM"

        [ ! -L $S_AppOptInsDir ]  &&  ln -s $App_INS_BASE/tomcat_$NUM        $S_AppOptInsDir  
        [ ! -L $S_AppConfInsDir ]  &&  ln -s $App_INS_BASE/tomcat_$NUM/conf   $S_AppConfInsDir
        [ ! -L $S_AppLogInsDir ] &&  ln -s $App_INS_BASE/tomcat_$NUM/logs   $S_AppLogInsDir
    done
}

finstance()
{
    local S_INS_DIR="$1"
    local A_INS_SUBDIR=(conf webapps logs work temp)
    
    for SUBDIR in ${A_INS_SUBDIR[@]}
    do
        [ ! -d "$S_INS_DIR/$SUBDIR" ] && mkdir -p "$S_INS_DIR/$SUBDIR"
    
        cp -a $App_INS_BASE/../conf/*  $S_INS_DIR/conf/
    done
}


finstances()
{
    local A_INSNUM="$@"

    for NUM in ${A_INSNUM[@]}
    do
        [ ! -d "$App_INS_BASE/tomcat_$NUM" ] && finstance "$App_INS_BASE/tomcat_$NUM"
    done
}


#初始化
finit()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do
        S_AppOptInsDir="$App_INS_BASE/tomcat_$NUM"
        fpid "$S_AppOptInsDir"

        if [ -z "$AppPid" ]; then
            fsymlink $NUM && fcpconf $NUM
            [ -L $AppOptBase/tomcat_$NUM ] && [ -L $AppConfBase/tomcat_$NUM ] && [ -d $AppLogBase/tomcat_$NUM ] && echo "tomcat_$NUM 已初始化"
        else
            echo "tomcat_$NUM 正在运行"
        fi  
    done
}


# 更新
fupdate()
{
    if [ -d "$AppInstallDir" ];then

        echo "tomcat_base 已安装"
    else

        test -d "$AppBuildDir" && rm -rf $AppBuildDir
        tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
        mv $AppBuildDir $AppInstallDir && mkdir -p "$AppInstallDir/tomcat_ins"
	cp -vf $ScriptDir/catalina.sh    /App/install/OPS/$App/bin/
    fi


    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        S_AppOptInsDir="$App_INS_BASE/tomcat_$NUM"
        fpid "$S_AppOptInsDir"

        fbackup $NUM && finstances $NUM
            
        if [ $? -eq 0 ]; then
            echo "tomcat_$NUM 安装成功"
            rm -rf $AppInstallDir/webapps/*
        else
            echo "tomcat_$NUM 安装失败"
            exit
        fi
    done
}

# 启动
fstart()
{
    local A_INS_NUM="$@"
    local JAVA_OPTS_DEFAULT=$JAVA_OPTS

    for NUM in ${A_INS_NUM[@]}
    do
        S_AppOptInsDir="$AppOptBase/tomcat_$NUM"
        S_AppBinDir="$App_INS_BASE/../bin"
        S_AppStartup=$S_AppBinDir/startup.sh

        fpid "$S_AppOptInsDir"

        if [ -n "$AppPid" ]; then
            echo "tomcat_$NUM 正在运行"
        else
            local PORT=$((8080 + $NUM))

            if [[ $PORT -ge 8080 && $PORT -le 8099 ]];then 
		local  IP=$(ifconfig|sed -n 's/inet addr:\(.*\)Bcast.*/\1/gp'|sed -n 's/ //gp'|grep "192.168")
                export JAVA_OPTS="$JAVA_OPTS_DEFAULT -Dmyapp.name='$IP:$PORT' -Dlog.path='/App/log/OPS/tomcat_$NUM/business'"
            else
                echo 超出端口设定范围，端口应设定在8080-8099之间,请重新设定该实例端口并执行cpconf
            fi

            rm -rf $S_AppOptInsDir/work/* $S_AppOptInsDir/temp/*
            export CATALINA_BASE="$S_AppOptInsDir"
            $S_AppStartup
            if [ $? -eq 0 ]; then
                echo "启动 tomcat_$NUM"
            else
                echo "tomcat_$NUM 启动失败"
            fi
        fi
    done
}

# 重启
frestart()
{
   
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        S_AppOptInsDir="$AppOptBase/tomcat_$NUM"
        fpid "$S_AppOptInsDir"

        test -n "$AppPid" && fstop $NUM && echo "stopped $AppPid " 
    done
    fstart ${A_INS_NUM[@]}
}

# 停止
fstop()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        S_AppOptInsDir="$AppOptBase/tomcat_$NUM"
        fpid "$S_AppOptInsDir"

        if [ -n "$AppPid" ]; then
            echo "$AppPid" | xargs kill -9
            if [ $? -eq 0 ]; then
                echo "终止 tomcat_$NUM 进程"
            else
                echo "终止 tomcat_$NUM 进程失败"
                exit
            fi
        else
            echo "tomcat_$NUM 进程未运行"
        fi
    done
}

# 切割日志
fcutlog()
{
    local A_INS_NUM="$@"

    for NUM in ${A_INS_NUM[@]}
    do  
        S_AppOptInsDir="$App_INS_BASE/tomcat_$NUM"
        fpid "$S_AppOptInsDir"

        Time=$(date +'%Y-%m-%d %H:%M:%S')
        Day=$(date -d '-1 days' +'%Y-%m-%d')
        SaveDays=30

        echo "$Time"
        find $AppLogDir -type f -mtime +$SaveDays -exec rm -f {} \;
        mv -vf --backup=numbered $AppLogBase/tomcat_$NUM/logs/catalina.out $AppLogBase/tomcat_$NUM/logs/catalina.$Day.out && echo "切割 $AppName 日志"
        frestart $NUM
    done
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) shift 1; finstall $@;;
    "update"    ) shift 1; fupdate $@;;
    "reinstall" ) shift 1; fremove $@ && finstall $@;;
    "remove"    ) shift 1; fremove $@;;
    "backup"    ) shift 1; fbackup $@;;
    "start"     ) shift 1; fstart $@;;
    "stop"      ) shift 1; fstop $@;;
    "restart"   ) shift 1; frestart $@;;
    "status"    ) shift 1; fstatus $@;;
    "cpconf"    ) shift 1; fcpconf $@;;
    "init"      ) shift 1; finit $@;;
    "ins"       ) shift 1; finstances $@;;
    "cutlog"    ) shift 1 fcutlog $@;;
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
    echo "$ScriptFile cpconf               拷贝 $AppName 配置"
    echo "$ScriptFile init               初始化 $AppName 配置"
    echo "$ScriptFile cutlog               切割 $AppName 日志"
    ;;
esac
