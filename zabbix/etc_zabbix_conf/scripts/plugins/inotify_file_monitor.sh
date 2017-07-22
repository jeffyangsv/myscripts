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

    local FM_TARGET="$1"
    local FM_LOG_CURRENT_DATE_ARRAY=($(ps -ef|grep "inotifywait -mrqd -o"|grep $FM_TARGET|egrep -o '[0-9]{4}-[0-9]{2}-[0-9]{2}'|sort -n|uniq))
    local FM_LOG_PASSED_DATE_ARRAY=($(echo "${FM_LOG_CURRENT_DATE_ARRAY[@]}"|grep -v "$TODAY"))
    local HAS_FM_LOG_TODAY_DATE=$(echo "${FM_LOG_CURRENT_DATE_ARRAY[@]}" | grep $TODAY > /dev/null && echo 1 || echo 0 )

    if [ "x$HAS_FM_LOG_TODAY_DATE" == "x0" ];then
    
        fstart "$FM_TARGET" "create" > /dev/null 2>&1 && \
        fstart "$FM_TARGET" "delete" > /dev/null 2>&1
    fi

    for FM_PASSED_DATE in ${FM_LOG_PASSED_DATE_ARRAY[@]}
    do

        fstop  "$FM_TARGET" "$FM_PASSED_DATE" > /dev/null 2>&1

    done
}

function fmonitor()
{
    local FM_TARGET="$1"
    local FM_TRIGGER_TYPE="$2"
    local FM_LOG_SUB_DIR=$(echo "$FM_TARGET"|awk -F'/' '{if($NF == "")print $0;else print $0"/"}'|sed -n 's#/#_#gp')
    local FM_LOG_SUB_DIR="$FM_LOG_DIR/$FM_LOG_SUB_DIR"

    case "$FM_TRIGGER_TYPE" in 
    proc_status)
        [ ! -n "$(ps -ef|grep "inotifywait -mrqd"|grep "$FM_TARGET"|grep -v grep)" ] && \
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
    FM_TARGET_ARRARY=($(ps -ef|grep "inotifywait -mrqd"|grep -v grep|awk '{print $NF}'|sort -n|uniq 2>/dev/null))
    length=${#FM_TARGET_ARRARY[@]}
    printf "{\n"
    printf  '\t'"\"data\":["
    for ((i=0;i<$length;i++))
    do
        printf '\n\t\t{'
        printf "\"{#FM_TARGET}\":\"${FM_TARGET_ARRARY[$i]}\"}"
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
    local FM_TARGET="$1"
    local FM_TARGET=$(echo "$FM_TARGET"|awk -F'/' '{if($NF ~ "^$")print $0;else print $0"/"}')
    local FM_ACTION="$2"
    local FM_LOG_SUB_DIR=$(echo "$FM_TARGET"|sed -n 's#/#_#gp')
    local FM_LOG_SUB_DIR="$FM_LOG_DIR/$FM_LOG_SUB_DIR"
    [ ! -d "$FM_LOG_SUB_DIR" ] && mkdir -p "$FM_LOG_SUB_DIR"

    inotify_handler "$FM_TARGET" "$FM_ACTION" "$FM_LOG_SUB_DIR"
}

function fstop()
{
    local FM_TARGET=$1
    local FM_LOG_SUB_DIR=$2
    ps -ef | grep -v grep | grep inotify | egrep -i "($FM_TARGET|$FM_TARGET/)" | egrep -i "$FM_LOG_SUB_DIR" | awk '{print $2}'  | xargs kill -9

}


case $1 in
start)
    FM_TARGET=$2
    fstart "$FM_TARGET" "create" > /dev/null 2>&1
    fstart "$FM_TARGET" "delete" > /dev/null 2>&1
;;
stop)
    FM_TARGET=$2
    FM_LOG_DATE=$3
    fstop "${FM_TARGET:-inotify}" "${FM_LOG_DATE}" #> /dev/null 2>&1
;;
monitor)
    FM_TARGET=$2
    FM_TRIGGER_TYPE=$3
    fmonitor "$FM_TARGET" "$FM_TRIGGER_TYPE"
;;
discovery)
   fdiscovery 
;;
cutlog)
    FM_TARGET=$2
    fcutlog "$FM_TARGET" && fclean
;;
clean)
    fclean
;;
*)
    fhelp
;;
esac
