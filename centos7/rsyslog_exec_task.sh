#!/bin/bash
#---------------------------------------------------
#Name:        rsyslog_exec_task.sh
#Version:     v1.0
#Create_Date：2017-9-8
#Author:      GuoLikai
#Description: "Error级别日志收集并发送报警邮件"
#---------------------------------------------------

#priority: 级别日志级别低到高
SyslogPriority=('emerg' 'alert' 'crit' 'error' 'warning' 'notice' 'info' 'debug')
#facility: 日志设备(可以理解为日志类型) --> 下面数组信息不准确
SyslogFacility=('auth' 'authpriv' 'cron' 'kern' 'lpr' 'mail' 'rsyslog' 'news' 'user' 'uucp' 'loca1 1' 'loca1 2' 'loca1 3' 'loca1 4' 'loca1 5' 'loca1 6' 'loca1 7')

ApplogBase=/App/log/SRT
ApplogDir=${ApplogBase}/rsyslog
AppScriptDir=/App/script/OPS/rsyslog
Today=$(date  +'%Y-%m-%d')
Yesterday=$(date -d '-1 days' +'%Y-%m-%d')
BackUpDir=${ApplogBase}/rsyslog_back/$Yesterday
step=5

#日志文件MD5值获取
flogMD5(){
#    find ${ApplogDir}  -type f -print0 | xargs -0 md5sum | grep -v '-' >  ${ApplogBase}/md5_old_${Today}.log
    find ${ApplogDir}  -type f -print0 | xargs -0 md5sum | grep ${ApplogDir}   >  ${ApplogBase}/md5_old_${Today}.log
    if [[ ! -f ${ApplogBase}/rsyslog_script_${Today}.log ]];then
        echo  "${ApplogBase}/rsyslog_script_${Today}.log不存在"
        touch  ${ApplogBase}/rsyslog_script_${Today}.log
    fi
}

#发送邮件脚本
fSendMail(){
    Theme=$1
    Msg=$2
    if [[ $Theme ]];then
        /usr/bin/python  ${AppScriptDir}/alert_send_mail_srt.py "${Theme}"  "${Msg}"  &&   echo "${Theme}"   >> ${ApplogBase}/rsyslog_script_${Today}.log
        echo "$(date +%Y-%m-%d_%H:%M:%S) 日志报警邮件已发送"
    fi
}

#日志文件错误信息获取,并报警
flogDiff(){

/usr/bin/md5sum -c ${ApplogBase}/md5_old_${Today}.log | egrep  "FAILED|失败"  > ${ApplogBase}/md5sum_${Today}.log
if [[  -s ${ApplogBase}/md5sum_${Today}.log  ]];then
    for item in $(cat ${ApplogBase}/md5sum_${Today}.log | awk -F ':' '{print $1}')
    do
        Host=$(tail -1 ${item} | awk '{print $4}')
        if [[  "${Host}" ]];then
            SyslogPriority=$(tail -1 ${item} | awk '{print $5}')
            Time=$(tail -1 ${item} | awk '{print $3}')
            ErrType=$(tail -1 ${item} | awk '{print $6}' | awk -F':' '{print $1}')
            Info=$(tail -1 ${item} | awk '{for(i=6;i<=NF;i++) printf $i""FS;print ""}')
            Theme="服务器日志告警:${Host} 时间:${Time} 发生:${ErrType}故障"
            ThemeFile=$(echo ${Theme} | sed 's#:#\\:#g'|sed 's#\.#\\.#g'|sed 's#\[#\\[#g'|sed 's#\]#\\]#g')
            Msg="日志等级:${SyslogPriority} 问题详情:$Info"
            if [[ $(egrep "${ThemeFile}" ${ApplogBase}/rsyslog_script_${Today}.log | wc -l ) -eq 0 ]];then
                fSendMail "${Theme}"  "${Msg}"
            fi
        fi
    done
else
    echo "$(date +%Y-%m-%d_%H:%M:%S) 服务器日志没告警"
fi
}

#主函数
fmain(){
    flogMD5
for (( i = 1; i < $[300/${step}]; i=(i+1) )); 
do
#    echo "5分钟内第${i}次循环,$(date +%H:%M:%S)"
    flogDiff
    sleep ${step}
done
    exit 0
}


#凌晨1点日志移动
flogMv(){
     mkdir  -p  ${BackUpDir} 
     mv ${ApplogBase}/md5_old_${Yesterday}.log   ${BackUpDir} && \
     mv ${ApplogBase}/md5sum_${Yesterday}.log    ${BackUpDir} && \
     mv ${ApplogBase}/rsyslog_script_${Yesterday}.log  ${BackUpDir} && \
     cat ${BackUpDir}/md5_old_${Yesterday}.log | awk '{print $2}' | xargs -i  mv  {} ${BackUpDir} &
}

#凌晨0点rsyslog日志切割
flogCut(){
    if [ -f ${ApplogDir}/rsyslog.log ];then
#        mv  /App/log/SRT/rsyslog/rsyslog.log  /App/log/SRT/rsyslog/rsyslog_`date -d '-1 days' +'%Y%m%d'`.log
        mv  ${ApplogDir}/rsyslog.log  ${ApplogDir}/rsyslog_${Yesterday}.log
    fi
    /etc/init.d/rsyslog  restart
}


ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "logmd5"    )    flogMD5;;
    "logdiff"   )    flogDiff;;
    "sendmail"  )    fSendMail $2 $3;;
    "logmv"     )    flogMv;;
    "logcut"    )    flogCut;;
    "main"      )    fmain;;
    *           )
    echo "$ScriptFile logmd5              MD5 $AppName"
    echo "$ScriptFile logdiff             对比 $AppName"
    echo "$ScriptFile sendmail Theme Msg  邮件 $AppName"
    echo "$ScriptFile logmv               移动 $AppName"
    echo "$ScriptFile logcut              切割 $AppName"
    echo "$ScriptFile main                执行 $AppName"
    ;;
esac
