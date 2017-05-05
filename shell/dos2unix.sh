#!/bin/sh
##################################################
#Name:        dos2unix.sh
#Version:     v1.0
#Create_Date：2017-2-15
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "windows文件编码方式到linux的转换"
##################################################

foreachd () {
  echo $1
  for file in $1/*
  do
    if [ -d $file ]
    then
      echo "directory $file"
      foreachd $file
    fi

    if [ -f $file ]
    then
      echo "file $file"
      dos2unix $file
      chmod -x $file
    fi

  done
}

echo $0
a=`echo $1`
if [ $# -gt 0 ]
then
  foreachd $a
else
  foreachd "."
fi
