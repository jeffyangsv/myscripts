#!/bin/bash
#-------------------------------------------------
#Name:        cdn_url_fenfa.sh
#Version:     v1.0
#Create_Date：2018-03-20
#Author:      GuoLikai
#Description: "逸云CDN新视频分发:ts(url)生成脚本"
#-------------------------------------------------

Dir='/root'
ResultFile='url_lists.txt'
ErrLog='url_err.log'
MovieType='m'

fExecUrl(){
    Item=$1

    echo  "分析开始:${Item}"
    start_url=$(echo $Item | sed "s/.flv/_${MovieType}/")
    m3u8_dir=$(echo $Item  |awk -F'cn' '{print $2}' | sed 's/video.*//')
    m3u8_name=$(echo $Item | awk -F'/' '{print $NF}'|sed "s/.flv/_${MovieType}.m3u8/")
    m3u8_url=$(echo ${start_url}/${m3u8_name})
    mkdir -p ${Dir}/${m3u8_dir}
    /usr/bin/wget ${start_url}/${m3u8_name}  -O ${Dir}/${m3u8_dir}/${m3u8_name}
    if [[ $? -eq 0 ]];then
        echo "${start_url}/${m3u8_name}"  >> ${Dir}/${ResultFile}
        for url in $(cat ${Dir}/${m3u8_dir}/${m3u8_name}| egrep -v "^#")
        do
            #echo ${start_url}/${url}
            echo "${start_url}/${url}"  >> ${Dir}/${ResultFile}
        done
    else
        echo "${Item}"  >> ${Dir}/${ErrLog}
    fi
    echo "分析结束!"

}


fExecFile(){
    File=$1
    echo ${File}
    echo "CDN视频预热路径分析开始......"
    > ${Dir}/${ResultFile}
    > ${Dir}/${ErrLog}
    for item in $(cat ${Dir}/${File})
    do
        fExecUrl ${item}
    done
    echo "CDN视频预热路径分析开始结束!"
    echo "分析成功文件:${Dir}/${ResultFile}"
    echo "出错记录文件:${Dir}/${ErrLog}"
}
ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "execfile"  ) fExecFile $2;;
    "execurl"   ) fExecUrl $2;;
    *           )
    echo "$ScriptFile execfile 文件 $AppName"
    echo "$ScriptFile execurl  URL  $AppName"
    ;;
esac
