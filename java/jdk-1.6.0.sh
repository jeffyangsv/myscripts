
#!/bin/sh
##################################################
#Name:        jdk-1.6.0.sh
#Version:     jdk-1.6.0
#Create_Date: 2017-4-25
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "安装配置JDK 6"
##################################################

App=jdk-1.6.0
AppName=jdk
AppOptBase=/App/opt/OPS
AppOptDir=$AppOptBase/$AppName
AppInstallBase=/App/install/OPS
AppInstallDir=$AppInstallBase/$App
AppSrcBase=/App/src/OPS
AppTarBall=${App}.tar.gz
AppBuildBase=/App/build/OPS
AppBuildDir=$(echo "$AppBuildBase/$AppTarBall" | sed -e 's/.tar.*$//' -e 's/^.\///')
echo $AppBuildDir
Community=JvmSnmp345
AllowHost=192.168.0.0/16

# 安装
finstall() {
    [ -d "$JAVA_HOME" ] && echo "$AppName 已安装" && exit

    [ -d "$AppBuildDir" ] && rm -rf $AppBuildDir

    tar zxf $AppSrcBase/$AppTarBall -C $AppBuildBase || tar jxf $AppSrcBase/$AppTarBall -C $AppBuildBase
    mv $AppBuildDir $AppInstallDir && echo "$AppName 安装成功" || echo "$AppName 安装失败"
}


#创建软连接                                                                                                                            
fsymlink()
{
    [ -L $AppOptDir ] && rm -f $AppOptDir 

    ln -s $AppInstallDir  $AppOptDir
}

# 初始化
finit() {
fsymlink &&\
grep -q "JAVA_HOME" /etc/profile || cat >> /etc/profile << EOF
########################################
export JAVA_HOME=$AppOptDir
export JRE_HOME=\$JAVA_HOME/jre
export PATH=\$JAVA_HOME/bin:\$JRE_HOME/bin:\$PATH
export CLASSPATH=\$JAVA_HOME/lib:\$JRE_HOME/lib:./
EOF

cd $AppOptDir/jre/lib/management

cat > snmp.acl << EOF
acl = {
  {
    communities = $Community
    access = read-only
    managers = 127.0.0.1, $AllowHost
  }
}

trap = {
  {
    trap-community = $Community
    hosts = 127.0.0.1, $AllowHost
  }
}
EOF

cat > management.properties << EOF
com.sun.management.snmp.interface=0.0.0.0
com.sun.management.snmp.acl=true
com.sun.management.snmp.acl.file=$AppOptDir/jre/lib/management/snmp.acl
EOF

chmod 600 snmp.acl management.properties
[ $? -eq 0 ] && echo "初始化 $AppName 配置" || echo "初始化 $AppName 配置失败"
}

# 删除
fremove() {

    rm -rf $AppInstallDir && rm -f $AppOptDir
    [ ! -d $AppInstallDir ] && [ ! -f $AppOptDir ] && echo "删除 $AppName"
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)
case "$1" in
    "install"  ) finstall;;
    "remove"   ) fremove;;
    "reinstall") fremove && finstall;;
    "init"     ) finit;;
    * )
        echo "用法：$ScriptFile {install|remove|reinstall|init}"
        ;;
esac
