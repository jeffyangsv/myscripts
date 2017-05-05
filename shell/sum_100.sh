#!/bin/bash
##################################################
#Name:        sum_100.sh
#Version:     v1.0
#Create_Date：2016-3-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "100以内数字求和"
##################################################
sum=0
for ((i=1;i<=100;i++))
do
sum=`expr $i + $sum `
done
echo $sum
