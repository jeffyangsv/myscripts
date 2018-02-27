#!/bin/sh
# 编译安装管理Nginx
App=nginx
AppName=Nginx
AppBase=/App
AppDir=$AppBase/$App
AppProg=$AppDir/sbin/nginx
AppConf=$AppDir/conf/nginx.conf

AppSrcBase=/App/src
AppSrcFile=$App-*.tar.*
AppSrcDir=$(find $AppSrcBase -maxdepth 1 -name "$AppSrcFile" -type f 2> /dev/null | sed -e 's/.tar.*$//' -e 's/^.\///')
AppUser=$(grep "^[[:space:]]*user" $AppConf 2> /dev/null | sed 's/;//g' | awk '{print $2}')
AppGroup=$(grep "^[[:space:]]*user" $AppConf 2> /dev/null | sed 's/;//g' | awk '{print $3}')
AppPidDir=$(dirname $(grep "^[[:space:]]*pid" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//') 2> /dev/null)
AppErrorLogs=$(grep "^[[:space:]]*error_log" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')
AppAccessLogs=$(grep "^[[:space:]]*access_log" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')
AppProxyTempDir=$(grep "^[[:space:]]*proxy_temp_path" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')
AppProxyCacheDir=$(grep "^[[:space:]]*proxy_cache_path" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')
AppFastCGITempDir=$(grep "^[[:space:]]*fastcgi_temp_path" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')
AppFastCGICacheDir=$(grep "^[[:space:]]*fastcgi_cache_path" $AppConf 2> /dev/null | awk '{print $2}' | sed 's/;$//')

AppUser=${AppUser:-nobody}
AppGroup=${AppGroup:-nobody}
AppPidDir=${AppPidDir:-$AppDir/logs}
AppErrorLogs=${AppErrorLogs:-$AppDir/logs/error.log}
AppAccessLogs=${AppAccessLogs:-$AppDir/logs/access.log}

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "nginx: master process" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    AppWorkerPid=$(ps ax | grep "nginx: worker process" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    AppCacheManagerPid=$(ps ax | grep "nginx: cache manager process" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    AppCacheLoaderPid=$(ps ax | grep "nginx: cache loader process" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
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
        if [ -d "$AppDir" ]; then
            rm -rf $AppDir && echo "删除 $AppName"
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
    BackupFile=$App-$Day.tgz

    if [ -f "$AppProg" ]; then
        cd $AppBase
        tar zcvf $BackupFile --exclude=logs/* $App --backup=numbered
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
        [ $? -ne 0 ] && fupdate && fcpconf
    else
        echo "$AppName 正在运行"
    fi
}

# 拷贝配置
fcpconf()
{
    cp -vf --backup=numbered $ScriptDir/nginx.conf $AppConf
    cp -vf --backup=numbered $AppDir/conf/fastcgi.conf $AppDir/conf/fastcgi.conf 
    sed -i 's#/$nginx_version##' $AppDir/conf/fastcgi.conf
}

# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup

    cd $AppSrcBase
    test -d "$AppSrcDir" && rm -rf $AppSrcDir

    tar zxf $AppSrcFile || tar jxf $AppSrcFile
    cd $AppSrcDir

    ./configure \
    "--prefix=$AppDir" \
    "--with-http_stub_status_module" \
    "--without-http_auth_basic_module" \
    "--without-http_autoindex_module" \
    "--without-http_browser_module" \
    "--without-http_geo_module" \
    "--without-http_limit_req_module" \
    "--without-http_limit_conn_module" \
    "--without-http_map_module" \
    "--without-http_memcached_module" \
    "--without-http_scgi_module" \
    "--without-http_split_clients_module" \
    "--without-http_userid_module" \
    "--without-http_uwsgi_module" \
    "--without-mail_imap_module" \
    "--without-mail_pop3_module" \
    "--without-mail_smtp_module" \
    "--without-poll_module" \
    "--without-select_module" 

    [ $? -eq 0 ] && make && make install

    if [ $? -eq 0 ]; then
        echo "$AppName $Operate成功"
    else
        echo "$AppName $Operate失败"
        exit 1
    fi
}

# 初始化
finit()
{
    echo "初始化 $AppName"

    id -gn $AppGroup &> /dev/null
    if [ $? -ne 0 ]; then
        groupadd $AppGroup && echo "新建 $AppName 运行组：$AppGroup"
    else
        echo "$AppName 运行组：$AppGroup 已存在"
    fi
    
    id -un $AppUser &> /dev/null
    if [ $? -ne 0 ]; then
        useradd -s /bin/false -M -g $AppGroup $AppUser
        if [ $? -eq 0 ]; then
            echo "新建 $AppName 运行用户：$AppUser"
            echo "s0ngNg1nx69#1" | passwd --stdin $AppUser &> /dev/null
        fi
    else
        echo "$AppName 运行用户：$AppUser 已存在"
    fi

    cd $AppDir

    if [ ! -e "$AppPidDir" ]; then
        mkdir -p $AppPidDir && echo "新建 $AppName PID 文件目录：$AppPidDir"
    else
        echo "$AppName PID 文件目录：$AppPidDir 已存在"
    fi

    for AppErrorLog in $AppErrorLogs
    do
        AppErrorLogDir=$(dirname $AppErrorLog)
        if [ ! -e "$AppErrorLogDir" ]; then
            mkdir -p $AppErrorLogDir && echo "新建 $AppName 错误日志目录：$AppErrorLogDir"
        else
            echo "$AppName 错误日志目录：$AppErrorLogDir 已存在"
        fi
    done

    for AppAccessLog in $AppAccessLogs
    do
        AppAccessLogDir=$(dirname $AppAccessLog)
        if [ ! -e "$AppAccessLogDir" ]; then
            mkdir -p $AppAccessLogDir && echo "新建 $AppName 访问日志目录：$AppAccessLogDir"
        else
            echo "$AppName 访问日志目录：$AppAccessLogDir 已存在"
        fi
    done
    
    if [ -n "$AppProxyTempDir" ]; then
        if [ ! -e "$AppProxyTempDir" ]; then
            mkdir -p $AppProxyTempDir && echo "新建 $AppName 代理临时目录：$AppProxyTempDir"
        else
            echo "$AppName 代理临时目录：$AppProxyTempDir 已存在"
        fi
    fi
    
    if [ -n "$AppProxyCacheDir" ]; then
        if [ ! -e "$AppProxyCacheDir" ]; then
            mkdir -p $AppProxyCacheDir && echo "新建 $AppName 代理缓存目录：$AppProxyCacheDir"
        else
            echo "$AppName 代理缓存目录：$AppProxyCacheDir 已存在"
        fi
    fi
    
    if [ -n "$AppFastCGITempDir" ]; then
        if [ ! -e "$AppFastCGITempDir" ]; then
            mkdir -p $AppFastCGITempDir && echo "新建 $AppName FastCGI临时目录：$AppFastCGITempDir"
        else
            echo "$AppName FastCGI临时目录：$AppFastCGITempDir 已存在"
        fi
    fi
    
    if [ -n "$AppFastCGICacheDir" ]; then
        if [ ! -e "$AppFastCGICacheDir" ]; then
            mkdir -p $AppFastCGICacheDir && echo "新建 $AppName FastCGI缓存目录：$AppFastCGICacheDir"
        else
            echo "$AppName FastCGI缓存目录：$AppFastCGICacheDir 已存在"
        fi
    fi
}

# 检查配置
ftest()
{
    $AppProg -t && echo "$AppName 配置正确" || echo "$AppName 配置错误"
}

# 启动
fstart()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        echo "$AppName 正在运行"
    else
        $AppProg && echo "启动 $AppName" || echo "$AppName 启动失败"
    fi
} 

# 停止
fstop()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        $AppProg -s stop && echo "停止 $AppName" || echo "$AppName 停止失败"
    else
        echo "$AppName 未启动"
    fi
}

# 重载配置
freload()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        $AppProg -s reload && echo "重载 $AppName 配置" || echo "$AppName 重载配置失败"
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

    if [ -n "$AppWorkerPid" ]; then
        echo "$AppWorkerPid" | xargs kill -9
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 工作进程"
        else
            echo "终止 $AppName 工作进程失败"
        fi
    else
        echo "$AppName 工作进程未运行"
    fi

    if [ -n "$AppCacheManagerPid" ]; then
        echo "$AppCacheManagerPid" | xargs kill -9
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 缓存管理进程"
        else
            echo "终止 $AppName 缓存管理进程失败"
        fi
    else
        echo "$AppName 缓存管理进程未运行"
    fi

    if [ -n "$AppCacheLoaderPid" ]; then
        echo "$AppCacheLoaderPid" | xargs kill -9
        if [ $? -eq 0 ]; then
            echo "终止 $AppName 缓存加载进程"
        else
            echo "终止 $AppName 缓存加载进程失败"
        fi
    else
        echo "$AppName 缓存加载进程未运行"
    fi
}

# 切割日志
fcutlog()
{
    Time=$(date +'%Y-%m-%d %H:%M:%S')
    Day=$(date -d '-1 days' +'%Y-%m-%d') 
    SaveDays=30

    echo "$Time"
    for AppAccessLog in $AppAccessLogs
    do
        echo "$AppAccessLog" | grep -q "^/"
        if [ $? -eq 1 ]; then
            AppAccessLog=$AppDir/$AppAccessLog
        fi

        CutLog=$(echo "$AppAccessLog" | sed "s#\.log#.$Day.log#")
        find $(dirname $AppAccessLog) -name "*.log" -type f -mtime +$SaveDays -exec rm -f {} \;
        mv -vf --backup=numbered $AppAccessLog $CutLog && echo "切割 $AppName 访问日志"
    done 

    for AppErrorLog in $AppErrorLogs
    do
        echo "$AppErrorLog" | grep -q "^/"
        if [ $? -eq 1 ]; then
            AppErrorLog=$AppDir/$AppErrorLog
        fi

        CutLog=$(echo $AppErrorLog | sed "s#\.log#.$Day.log#")
        find $(dirname $AppErrorLog) -name "*.log" -type f -mtime +$SaveDays -exec rm -f {} \;
        mv -vf --backup=numbered $AppErrorLog $CutLog && echo "切割 $AppName 错误日志"
    done 

    $AppProg -s reload
}


ScriptDir=$(dirname $0)
ScriptFile=$(basename $0)
case "$1" in
    "install"   ) finstall;;
    "update"    ) fupdate;;
    "reinstall" ) fremove && finstall;;
    "remove"    ) fremove;;
    "backup"    ) fbackup;;
    "init"      ) finit;;
    "start"     ) fstart;;
    "stop"      ) fstop;;
    "restart"   ) frestart;;
    "status"    ) fstatus;;
    "cpconf"    ) fcpconf;;
    "test"      ) ftest;;
    "reload"    ) freload;;
    "kill"      ) fkill;;
    "cutlog"    ) fcutlog;;
    *           )
    echo "$ScriptFile install              安装 $AppName"
    echo "$ScriptFile update               更新 $AppName"
    echo "$ScriptFile reinstall            重装 $AppName"
    echo "$ScriptFile remove               删除 $AppName"
    echo "$ScriptFile backup               备份 $AppName"
    echo "$ScriptFile init                 初始化 $AppName"
    echo "$ScriptFile start                启动 $AppName"
    echo "$ScriptFile stop                 停止 $AppName"
    echo "$ScriptFile restart              重启 $AppName"
    echo "$ScriptFile status               查询 $AppName 状态"
    echo "$ScriptFile cpconf               拷贝 $AppName 配置"
    echo "$ScriptFile test                 检查 $AppName 配置"
    echo "$ScriptFile reload               重载 $AppName 配置"
    echo "$ScriptFile kill                 终止 $AppName 进程"
    echo "$ScriptFile cutlog               切割 $AppName 日志"
    ;;
esac
