#!/bin/bash
#---------------------------------------------------
#Name:        mysql_database_count.sh
#Version:     v1.0
#Create_Date：2017-11-2
#Author:      GuoLikai
#Description: "自定义数据库信息收集脚本"
#---------------------------------------------------

AppName=mysql
MYSQLPATH=$(which mysql)
MYSQLUSER=root
MYSQLPASS=123456
MYSQLSOCK=/tmp/mysql_3306.sock
Today=$(date  +'%Y-%m-%d')
Yesterday=$(date -d '-1 days' +'%Y-%m-%d')
BackUpDir=/root/workspace/backup
#BackUpDir=$(cd $(dirname $0); pwd)

MysqlConn="${MYSQLPATH} -u${MYSQLUSER} -p${MYSQLPASS} -S ${MYSQLSOCK}"

FGetMysqlDatabases(){
    ${MysqlConn} -e "show databases" | egrep -v "Database|information_schema|performance_schema|test"  > ${BackUpDir}/mysql_database_info_${Yesterday}.log
}

FGetMysqlSize(){
    >  ${BackUpDir}/mysql_count_size_${Yesterday}.log
    FGetMysqlDatabases
    if [[  -s ${BackUpDir}/mysql_database_info_${Yesterday}.log  ]];then
        for Database in $(cat ${BackUpDir}/mysql_database_info_${Yesterday}.log | awk '{print $1}')
        do
            Size=`${MysqlConn} -e "use information_schema;select concat(round(sum(data_length/1024/1024),2),'MB') as data from tables where table_schema='${Database}'" | grep -v data`
            if [[ "${Size}" != 'NULL' ]];then
#                echo "数据库[${Database}]大小是[${Size}]"
                echo "数据库[${Database}]大小是[${Size}]"  >>  ${BackUpDir}/mysql_count_size_${Yesterday}.log
            fi
        done
    fi    
   echo "数据库每个库大小详见文件:${BackUpDir}/mysql_count_size_${Yesterday}.log"
}


FGetMysqltables(){
    > ${BackUpDir}/mysql_database_table_info_${Yesterday}.log
    if [[  -s ${BackUpDir}/mysql_database_info_${Yesterday}.log  ]];then
        for Database in $(cat ${BackUpDir}/mysql_database_info_${Yesterday}.log | awk '{print $1}')
        do 
              for Table in $(${MysqlConn} -e "use ${Database};show tables" | grep -v "Tables_in")
              do
                  for Item in $(${MysqlConn} -e "desc ${Database}.${Table}" | grep -v "Field" | head -1 | awk '{print $1}')
                  do 
                      echo "${Database} ${Table} ${Item}"  >> ${BackUpDir}/mysql_database_table_info_${Yesterday}.log
                  done
              done
        done
    fi
}

FGetMysqlCount(){
    > ${BackUpDir}/mysql_count_records_${Yesterday}.log
   if [[ -s ${BackUpDir}/mysql_database_table_info_${Yesterday}.log ]];then
       cat ${BackUpDir}/mysql_database_table_info_${Yesterday}.log | while read Item
       do  
           if [[ ${Item} ]];then
               Database=$(echo ${Item} | awk '{print $1}')
               Table=$(echo ${Item} | awk '{print $2}')
               Attribute=$(echo ${Item} | awk '{print $3}')
               #echo "${MysqlConn} -e \"select count(${Attribute}) from ${Database}.${Table}\" | grep -v \"count\"" >> mysql_database_count_command_${Yesterday}.log
               Num=`${MysqlConn} -e "select count('${Attribute}') from ${Database}.${Table}" | grep -v "count"`
               if [[ ${Num} -ne 0 ]];then
#                    echo "库名:${Database} 表名:${Table} 记录数:${Num}"  
                   echo "库名:${Database} 表名:${Table} 记录数:${Num}"  >>  ${BackUpDir}/mysql_count_records_${Yesterday}.log
               fi
           fi
       done
    else
        echo "Please Execute:$0 main"
   fi
   echo "数据库每张表的记录数详见文件:${BackUpDir}/mysql_count_records_${Yesterday}.log"
}

FMain(){
   echo "数据库相关信息收集Starting"
   FGetMysqlDatabases && FGetMysqlSize && FGetMysqltables  && FGetMysqlCount
   echo "数据库相关信息收集End"
}

ScriptDir=$(cd $(dirname $0); pwd)
ScriptFile=$(basename $0)

case "$1" in
    "databases"        ) FGetMysqlDatabases;; 
    "size"             ) FGetMysqlSize;; 
    "tables"           ) FGetMysqltables;; 
    "count"            ) FGetMysqlCount;; 
    "main"             ) FMain;;
    *                  ) 
    echo "$ScriptFile databases         获取库名 $AppName"
    echo "$ScriptFile size              数据大小 $AppName"
    echo "$ScriptFile tables            获取表名 $AppName"
    echo "$ScriptFile count             统计行数 $AppName"
    echo "$ScriptFile main              脚本运行 $AppName"
    ;;
esac
