#!/bin/bash
#-------------------------------------------------
#Name:        cdn_url_fenfa.sh
#Version:     v1.0
#Create_Date：2018-03-20
#Author:      GuoLikai
#Description: "CDN新视频预缓存:ts(url)生成脚本"
#-------------------------------------------------

AppName='CdnUrlExecFenfa'
Dir='/App/script/SRT/cdn'
ErrLog='url_err.log'
YiyunFile='url_lists_yiyun.txt'
YunduanFile='url_lists_yunduan.txt'
MovieType='m'

fExecUrl(){
    Item=$1
    echo  "分析开始:${Item}"
    yiyun_url=$(echo ${Item} | sed "s/.flv/_${MovieType}/")
    #yunduan_url=$(echo ${yiyun_url} | sed "s/yuncdn.teacherclub.com.cn/coursecdn.teacherclub.com.cn/")
    yunduan_url=$(echo ${Item} | sed "s/.flv/_${MovieType}/" | sed "s/yuncdn.teacherclub.com.cn/coursecdn.teacherclub.com.cn/")
    m3u8_dir=$(echo ${Item}  |awk -F'cn' '{print $2}' | sed 's/video.*//')
    m3u8_name=$(echo ${Item} | awk -F'/' '{print $NF}'|sed "s/.flv/_${MovieType}.m3u8/")
    m3u8_url=$(echo ${yiyun_url}/${m3u8_name})
    mkdir -p ${Dir}/${m3u8_dir}
    /usr/bin/wget ${yiyun_url}/${m3u8_name}  -O ${Dir}/${m3u8_dir}/${m3u8_name}  &> /dev/null
    if [[ $? -eq 0 ]];then
        echo "${yiyun_url}/${m3u8_name}"   >> ${Dir}/${YiyunFile}
        echo "${yunduan_url}/${m3u8_name}"  >> ${Dir}/${YunduanFile}
        for url in $(cat ${Dir}/${m3u8_dir}/${m3u8_name}| egrep -v "^#")
        do
            echo "${yiyun_url}/${url}"    >> ${Dir}/${YiyunFile}
            echo "${yunduan_url}/${url}"  >> ${Dir}/${YunduanFile}
        done
    else
        echo "${Item}"  >> ${Dir}/${ErrLog}
    fi
    echo "分析结束!"
}


fExecFile(){
    File=$1
    > ${Dir}/${YiyunFile}
    > ${Dir}/${YunduanFile}
    > ${Dir}/${ErrLog}
    if [[ -f ${Dir}/${File} ]];then
        echo "${File}需要是unix格式"
        echo "CDN视频预缓存路径分析开始......"
        for item in $(cat ${Dir}/${File})
        do
            fExecUrl ${item}
        done
        echo "CDN视频预缓存路径分析开始结束!"
        echo "逸云分析成功文件:${Dir}/${YiyunFile}"
        echo "云端分析成功文件:${Dir}/${YunduanFile}"
        echo "出错记录文件:${Dir}/${ErrLog}"
    else
        echo "注意:${Dir}/${File}文件不存在!"
    fi
}
ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "execfile"  ) fExecFile $2;;
    "execurl"   ) fExecUrl $2;;
    *           )
    echo "${ScriptFile} execfile 文件 $AppName"
    echo "${ScriptFile} execurl  URL  $AppName"
    ;;
esac
