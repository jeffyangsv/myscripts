#!/bin/bash
################################################
# use dd cammand add disk space
# 2016-08-31 by liuzhihao
################################################
. /etc/init.d/functions
function add_disk(){
	for file in `seq $1`
	do
		dd if=/dev/zero of=/$2/test_${file} bs=$3 count=1 &> /dev/null
		if [ $? -eq 0 ];then
			action "/$2/test_${file} write success" /bin/true
			sleep $4
		else
			action "/$2/test_${file} write failed" /bin/false
		fi
	done
}
if [ "$#" -ne 4 ];then
	echo "error: You need to enter the 4 parameters" >&2	
	echo "parameters1: Number of file" >&2	
	echo "parameters2: Store directory" >&2	
	echo "parameters3: Size of each file" >&2	
	echo "parameters4: How much time waiting" >&2	
	exit 1                                              	
fi                                                          	
add_disk $1 $2 $3 $4
