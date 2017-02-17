#!/bin/bash
#
# Description: helpers for MySQL 
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

source /etc/profile

MYCNF_PATH="/etc/my.cnf"

# default timeout in seconds
MYSQL_TIMEOUT=${MYSQL_TIMEOUT:-5}

# client options
MYSQL_OPTS="--connect_timeout=$MYSQL_TIMEOUT"

which mysql &> /dev/null && MYSQL_BIN=$(which mysql) || {
  test -e /usr/bin/mysql && MYSQL_BIN=/usr/bin/mysql || { echo "Unable to locate mysql" >&2; exit 1; }
}
test ! -x $MYSQL_BIN && { echo "Unable to execute $MYSQL_BIN" >&2; exit 1; }

#
# performs a query in batch mode
#
function mysql_batch_query() {
  local opts=$1
  local query=$2

  #$MYSQL_BIN $opts $MYSQL_OPTS --batch --skip-column-names -e "$query"
  $MYSQL_BIN $opts $MYSQL_OPTS --batch -e "$query"
}

function mysql_discovery()
{
    local MYSQL_SOCKET_ARRAY=($(ps -ef|egrep "mysqld +"|grep -v grep|awk '{for(i=1;i<=NF;i++){if($i ~ "socket"){print $i}}}'|awk -F'=' '{print $NF}'))
    length=${#MYSQL_SOCKET_ARRAY[@]}
    printf "{\n"
    printf  '\t'"\"data\":["
    for ((i=0;i<$length;i++))
    do  
        printf '\n\t\t{'
        printf "\"{#MYSQL_SOCKET}\":\"${MYSQL_SOCKET_ARRAY[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
            printf ',' 
        fi  
    done
    printf  "\n\t]\n"
    printf "}\n"
}
