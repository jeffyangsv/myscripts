#!/bin/sh
#-------------------------------------------------
#Name:        php-5.6.30.sh
#Version:     v5.6.30
#Create_Date: 2017-5-18
#Author:      GuoLikai
#Description: "编译安装管理PHP"
#-------------------------------------------------

App=php-5.6.30
AppName=php
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
AppIni=$AppConfDir/php.ini
AppConf=$AppConfDir/php-fpm.conf
AppProg=$AppOptDir/sbin/php-fpm

AppSrcDir=$(find $AppSrcBase -maxdepth 1 -name "$AppSrcFile" -type f 2> /dev/null | sed -e 's/.tar.*$//' -e 's/^.\///')
AppUser=$(grep "^[[:space:]]*user" $AppConf 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")
AppGroup=$(grep "^[[:space:]]*group" $AppConf 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")
AppPidDir=$(dirname $(grep "^[[:space:]]*pid" $AppConf 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g") 2> /dev/null)
AppErrorLogDir=$(dirname $(grep "^[[:space:]]*error_log" $AppConf 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g") 2> /dev/null)
AppSlowLogDir=$(dirname $(grep "^[[:space:]]*slowlog" $AppConf 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g") 2> /dev/null)
UploadTmpDir=$(grep "^[[:space:]]*upload_tmp_dir" $AppIni 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")
grep "^session.save_handler" $AppIni 2> /dev/null | grep -q "files"
[ $? -eq 0 ] && SessionDir=$(grep "^[[:space:]]*session.save_path" $AppIni 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")
CacheDir=$(grep "^[[:space:]]*eaccelerator.cache_dir" $AppIni 2> /dev/null | awk -F= '{print $2}' | sed -e 's/[[:space:]]//g' -e 's/"//g' -e "s/'//g")

AppUser=${AppUser:-nobody}
AppGroup=${AppGroup:-nobody}
AppPidDir=${AppPidDir:=$AppInstallDir/var/run}
AppErrorLogDir=${AppErrorLogDir:-$AppInstallDir/var/log}
AppSlowLogDir=${AppSlowLogDir:-$AppInstallDir/var/log}

RemoveFlag=0
InstallFlag=0

# 获取PID
fpid()
{
    AppMasterPid=$(ps ax | grep "php-fpm: master process" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
    AppWorkerPid=$(ps ax | grep "php-fpm: pool" | grep -v "grep" | awk '{print $1}' 2> /dev/null)
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
        cd $AppBase
        tar zcvf $BackupFile --exclude=var/log/* --exclude=var/run/* $App --backup=numbered
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
        [ $? -ne 0 ] && frely && fupdate && fsymlink && fcpconf
    else
        echo "$AppName 正在运行"
    fi
}

#PHP依赖
frely()
{
	yum -y install epel-release
	yum -y install libmcrypt libmcrypt-devel mcrypt mhash 
	yum -y install zlib libxml libjpeg freetype libpng gd curl libiconv zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel openssl openssl-devel libxslt-devel
	#cd $AppSrcBase
	#if [ -f "$AppSrcBase/libmcrypt-2.5.8.tar.gz" ];then
	#    echo "libmcrypt-2.5.8.tar.gz源码包已存在"
	#else
	#    wget https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz/download &&  mv download libmcrypt-2.5.8.tar.gz
	#fi
	#tar -zxvf libmcrypt-2.5.8.tar.gz -C  $AppBuildBase
	#cd $AppBuildBase/libmcrypt-2.5.8
	#./configure --prefix=$AppInstallBase/libmcrypt
	#make
	#make install

	cd $AppSrcBase
	if [ -f "$AppSrcBase/libiconv-1.15.tar.gz" ];then
		echo "libiconv-1.15.tar.gz源码包已存在"
	else
		wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz 
	fi
	tar zxf libiconv-1.15.tar.gz -C $AppBuildBase
	cd $AppBuildBase/libiconv-1.15
	./configure --prefix=$AppInstallBase/libiconv
	make
	make install
}



# 更新
fupdate()
{
    Operate="更新"
    [ $InstallFlag -eq 1 ] && Operate="安装"
    [ $RemoveFlag -ne 1 ] && fbackup

    test -d "$AppBuildDir" && rm -rf $AppBuildDir
	if [ -f "$AppSrcBase/$AppTarBall" ];then
		echo "$AppTarBall源码包已存在"
	else
		wget http://tw1.php.NET/get/php-5.6.30.tar.gz/from/this/mirror  &&  mv mirror $AppTarBall
	fi 
    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    cd $AppBuildBase/$App
    ./configure --prefix=$AppInstallDir \
    --with-mysql=mysqlnd  \
    --with-mysqli=mysqlnd  \
    --with-pdo-mysql=mysqlnd  \
    --with-iconv-dir=$AppInstallBase/libiconv/ \
    --with-ldap \
    --with-gettext \
    --with-freetype-dir  \
    --with-jpeg-dir  \
    --with-png-dir  \
    --with-zlib  \
    --with-libxml-dir=/usr \
    --enable-xml  \
    --disable-rpath  \
    --enable-bcmath  \
    --enable-shmop  \
    --enable-sysvsem  \
    --enable-inline-optimization \
    --with-curl  \
    --enable-mbregex  \
    --enable-fpm  \
    --enable-mbstring  \
    --with-mcrypt  \
    --with-gd  \
    --enable-gd-native-ttf  \
    --with-openssl  \
    --with-mhash  \
    --enable-pcntl  \
    --enable-sockets  \
    --with-xmlrpc  \
    --enable-zip  \
    --enable-soap  \
    --enable-short-tags  \
    --enable-static  \
    --with-xsl  \
    --with-fpm-user=$AppUser  \
    --with-fpm-group=$AppGroup  \
    --enable-ftp  \
    --without-pear  \
    --disable-phar \
    --enable-opcache=no
	
    [ $? -eq 0 ] && make && make install
    if [ $? -eq 0 ];then
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
        useradd -s /bin/false -g $AppGroup -M $AppUser
        if [ $? -eq 0 ]; then
            echo "新建 $AppName 运行用户：$AppUser"
            echo "S0nGPhb693$" | passwd --stdin $AppUser &> /dev/null
        fi
    else
        echo "$AppName 运行用户：$AppUser 已存在"
    fi

    echo $AppPidDir | grep -q "^/"
    if [ $? -eq 1 ]; then
        AppPidDir=$AppInstallDir/var/$AppPidDir
    fi

    if [ ! -e "$AppPidDir" ]; then
        mkdir -p $AppPidDir && echo "新建 $AppName PID文件存放目录：$AppPidDir"
    else
        echo "$AppName PID文件存放目录：$AppPidDir 已存在"
    fi

    echo $AppErrorLogDir | grep -q "^/"
    if [ $? -eq 1 ]; then
        AppErrorLogDir=$AppInstallDir/var/$AppErrorLogDir
    fi

    if [ ! -e "$AppErrorLogDir" ]; then
        mkdir -p $AppErrorLogDir && echo "新建 $AppName 错误日志目录：$AppErrorLogDir"
    else
        echo "$AppErrorLogDir 错误日志目录：$AppErrorLogDir 已存在"
    fi

    echo $AppSlowLogDir | grep -q "^/"
    if [ $? -eq 1 ]; then
        AppSlowLogDir=$AppInstallDir/$AppSlowLogDir
    fi

    if [ ! -e "$AppSlowLogDir" ]; then
        mkdir -p $AppSlowLogDir && echo "新建 $AppName 慢日志目录：$AppSlowLogDir"
    else
        echo "$AppSlowLogDir 慢日志目录：$AppSlowLogDir 已存在"
    fi
    printf "\n"

    if [ -n "$UploadTmpDir" ]; then
        echo $UploadTmpDir | grep -q "^/"
        if [ $? -eq 0 ]; then
            if [ ! -e "$UploadTmpDir" ]; then
                mkdir -p $UploadTmpDir && echo "新建 $AppName 文件上传临时存储目录：$UploadTmpDir"
            else
                echo "$AppName 文件上传临时存储目录：$UploadTmpDir 已存在"
            fi

            chown -R $AppUser:$AppGroup $UploadTmpDir && echo "修改 $AppName 文件上传临时存储目录拥有者为 $AppUser，属组为 $AppGroup"
            printf "\n"
        fi
    fi

    if [ -n "$SessionDir" ]; then
        echo $SessionDir | grep -q "^/"
        if [ $? -eq 0 ]; then
            if [ ! -e "$SessionDir" ]; then
                mkdir -p $SessionDir && echo "新建 $AppName 会话存储目录：$SessionDir"
            else
                echo "$AppName 会话存储目录：$SessionDir 已存在"
            fi

            chown -R $AppUser:$AppGroup $SessionDir && echo "修改 $AppName 会话存储目录拥有者为 $AppUser，属组为 $AppGroup"
            printf "\n"
        fi
    fi

    if [ -n "$CacheDir" ]; then
        echo $CacheDir | grep -q "^/"
        if [ $? -eq 0 ]; then
            if [ ! -e "$CacheDir" ]; then
                mkdir -p $CacheDir && echo "新建 eAccelerator 缓存目录：$CacheDir"
            else
                echo "eAccelerator 缓存目录：$CacheDir 已存在"
            fi

            chown -R $AppUser:$AppGroup $CacheDir && echo "修改 eAccelerator 缓存目录拥有者为 $AppUser，属组为 $AppGroup"
        fi
    fi

    sed -i "s|extension_dir.*$|extension_dir = \"$ExtensionDir\"|" $AppIni
}


#创建软连接
fsymlink()
{
    [ -L $AppOptDir ] && rm -f $AppOptDir
    [ -L $AppConfDir ] && rm -f $AppConfDir
    [ -L $AppLogDir ] && rm -f $AppLogDir
    ln -s $AppInstallDir  $AppOptDir
    ln -s $AppInstallDir/etc $AppConfDir
    ln -s $AppInstallDir/var/log $AppLogDir
    ln -s $AppInstallDir/var/run/php-fpm.pid  $AppLogDir/php-fpm.pid
}

# 拷贝配置
fcpconf()
{
    #mkdir  $AppConfDir 
    cp  $AppBuildBase/$App/php.ini-production   $AppInstallDir/etc/php.ini
    cp  $AppInstallDir/etc/php-fpm.conf.default $AppInstallDir/etc/php-fpm.conf
    #ln -s $AppInstallDir/etc/php.ini  $AppConfDir/
    #ln -s $AppInstallDir/etc/php-fpm.conf  $AppConfDir/
    sed -i "/^\;pid/s#;##"  					$AppConfDir/php-fpm.conf	
    sed -i "/^user/cuser = nobody"   			$AppConfDir/php-fpm.conf
    sed -i "/^group/cgroup = nobody"   			$AppConfDir/php-fpm.conf
    sed -i "/^\;date.timezone/cdate.timezone=Asia/Shanghai" $AppConfDir/php.ini 
    sed -i "/^expose_php/s#On#Off#"  			  		 	$AppConfDir/php.ini
    sed -i "/^short_open_tag/s#Off#On#" 			   		$AppConfDir/php.ini 
    sed -i "/^\;opcache.enable\=0/copcache.enable=1" 		$AppConfDir/php.ini
    sed -i "/^\;opcache.enable_cli/copcache.enable_cli=0" 	$AppConfDir/php.ini 
    #piwik 安装时使用
    #if [ $(grep "end_extension=opcache.so" $AppConfDir/php.ini |wc -l) -eq 0 ];then
    #echo "end_extension=opcache.so
    #    always_populate_raw_post_data=-1" >> 				$AppConfDir/php.ini
    #fi
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
        echo "$AppProg -c $AppConfDir/${AppName}.ini -y $AppConfDir/${AppName}-fpm.conf && echo \"启动 $AppName\" || echo \"$AppName 启动失败\""
        $AppProg -c $AppConfDir/${AppName}.ini -y $AppConfDir/${AppName}-fpm.conf && echo "启动 $AppName" || echo "$AppName 启动失败"
    fi
}

# 停止
fstop()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        kill -INT $AppMasterPid && echo "停止 $AppName" || echo "$AppName 停止失败"
    else
        echo "$AppName 未启动"
    fi
}

# 重载配置
freload()
{
    fpid

    if [ -n "$AppMasterPid" ]; then
        kill -USR2 $AppMasterPid && echo "重载 $AppName 配置" || echo "$AppName 重载配置失败"
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
}


ScriptDir=$(cd $(dirname $0); pwd)
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
    ;;
esac
