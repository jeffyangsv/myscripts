#! /bin/bash

. /etc/init.d/functions

TODAY=$(date +%F)
#TODAY=$(date  --date='1 days ago' +%F)
FM_LOG_DIR="/data/fm_log"

function inotify_handler()
{
    local SRC="$1"
    local ACTION="$2"
    local FM_LOG_SUB_DIR="$3"
    CMD_INOTIFY="/usr/bin/inotifywait -mrqd -o '$FM_LOG_SUB_DIR/${ACTION}_${TODAY}.log' --timefmt '%F %H:%M' --format '%T %w%f %e' -e"
    eval "$CMD_INOTIFY $ACTION $SRC" 
}

function fhelp()
{
    echo "Usage:$0  {start <dir|file> | stop <dir|file> }"
}

function fclean()
{
    find $FM_LOG_DIR -type f -name "*.log" -mtime +7 -exec rm -f {} \;
}

function fcutlog()
{

    local FM_DIR="$1"

    fstart "$FM_DIR" "create" > /dev/null 2>&1 && \
    fstart "$FM_DIR" "delete" > /dev/null 2>&1 && \
    fstop  "$FM_DIR" "$(date --date='1 days ago' +%F)" > /dev/null 2>&1
}

function fmonitor()
{
    local FM_DIR="$1"
    local FM_TRIGGER_TYPE="$2"
    local FM_LOG_SUB_DIR=$(echo "$FM_DIR"|awk -F'/' '{if($NF == "")print $0;else print $0"/"}'|sed -n 's#/#_#gp')
    local FM_LOG_SUB_DIR="$FM_LOG_DIR/$FM_LOG_SUB_DIR"

    case "$FM_TRIGGER_TYPE" in 
    proc_status)
        [ ! -n "$(ps -ef|grep "inotifywait -mrqd"|grep "$FM_DIR"|grep -v grep)" ] && \
        echo 1 || echo 0
    ;;
    cutlog_status)
        [ ! -f "$FM_LOG_SUB_DIR/delete_${TODAY}.log" ] && echo 1 || echo 0
    ;;
    delete_status)
        [ -s "$FM_LOG_SUB_DIR/delete_${TODAY}.log" ] && echo 1 || echo 0
    ;;
    esac
}

function fdiscovery()
{
    FM_DIR_ARRARY=($(ps -ef|grep "inotifywait -mrqd"|grep -v grep|awk '{print $NF}'|sort -n|uniq 2>/dev/null))
    length=${#FM_DIR_ARRARY[@]}
    printf "{\n"
    printf  '\t'"\"data\":["
    for ((i=0;i<$length;i++))
    do
        printf '\n\t\t{'
        printf "\"{#FM_DIR}\":\"${FM_DIR_ARRARY[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
            printf ','
        fi
    done
    printf  "\n\t]\n"
    printf "}\n"
}

function fstart()
{
    [ $# != 2 ] && fhelp && exit 3
    local FM_DIR="$1"
    local FM_ACTION="$2"
    local FM_LOG_SUB_DIR=$(echo "$FM_DIR"|awk -F'/' '{if($NF == "")print $0;else print $0"/"}'|sed -n 's#/#_#gp')
    local FM_LOG_SUB_DIR="$FM_LOG_DIR/$FM_LOG_SUB_DIR"
    [ ! -d "$FM_LOG_SUB_DIR" ] && mkdir -p "$FM_LOG_SUB_DIR"

    inotify_handler "$FM_DIR" "$FM_ACTION" "$FM_LOG_SUB_DIR"
}

function fstop()
{
    local FM_DIR=$1
    local FM_LOG_SUB_DIR=$2
    ps -ef | grep -v grep | grep inotify | egrep -i "$FM_DIR" | egrep -i "$FM_LOG_SUB_DIR" | awk '{print $2}'  | xargs kill -9

}


case $1 in
start)
    FM_DIR=$2
    fstart "$FM_DIR" "create" > /dev/null 2>&1
    fstart "$FM_DIR" "delete" > /dev/null 2>&1
;;
stop)
    FM_DIR=$2
    FM_LOG_DATE=$3
    fstop "${FM_DIR:-inotify}" "${FM_LOG_DATE}" > /dev/null 2>&1
;;
monitor)
    FM_DIR=$2
    FM_TRIGGER_TYPE=$3
    fmonitor "$FM_DIR" "$FM_TRIGGER_TYPE"
;;
discovery)
   fdiscovery 
;;
cutlog)
    FM_DIR=$2
    fcutlog "$FM_DIR" && fclean
;;
clean)
    fclean
;;
*)
    fhelp
;;
esac
