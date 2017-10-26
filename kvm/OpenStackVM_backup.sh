#!/bin/bash

. /etc/init.d/functions
InstanceDir="/App/data/nova/instances"
BackupDir="/App/backup/OPS/OpenStackVM"
QemuCmd=$(which qemu-img)
instanceID=$1
LogDir="$BackupDir/$instanceID/back.log"
libvirtFile="$InstanceDir/$instanceID/libvirt.xml"
backinfo="$BackupDir/$instanceID/back.info"
Date=$(date +%F)

AuthID(){
	instance="$InstanceDir/$instanceID"
	if [ ! -e "$instance" ];then
		#WriteLog "$instance is not exits" 
		echo "$instance is not exits" 1>&2
		exit 1
	fi
}

WriteLog(){
	message=$1
	LogDate=$(date "+%F %T")
	echo "$LogDate $message" >> $LogDir

}

VMbackdir(){
	if [ ! -e "$BackupDir/$instanceID" ];then
		mkdir -p $BackupDir/$instanceID && WriteLog " [info] $BackupDir/$instanceID not exits. already create sucess"
	fi
	
}

VMinfo(){
	VMflavor=$(grep -w 'flavor name' $libvirtFile | sed -r 's/(<|>)//g'|awk '{print $NF}')
	VMname=$(grep -w 'name.instance' $libvirtFile | sed -r 's/(<|>)/ /g'|awk '{print $1"="$2}')
	VMimage=$(grep -w 'image.*uuid' $libvirtFile |  awk '{print $NF}'|sed -r 's#(/|>)##g')
	echo -e " flavor $VMflavor \n VM $VMname \n image $VMimage" > $backinfo && WriteLog " [info] write $instanceID vm information to $backinfo."
}

BackDisk(){
	diskinfo="$InstanceDir/$instanceID/disk.info"
	instanceIDdir="$InstanceDir/$instanceID"
	instanceBackdir="$BackupDir/$instanceID"
	diskList=$(ls "$instanceIDdir" | grep 'disk' |grep -v 'disk.info')
	for disk in ${diskList[*]}
	do
		diskfile="$instanceBackdir/${disk}_${Date}"
		$QemuCmd convert $instanceIDdir/$disk -O qcow2 $diskfile &&  WriteLog " [info] $instanceID $disk export to $diskfile." || WriteLog " [error] $instanceID $disk export error."
		if [ "$?" -eq 0 ];then
			gzip $diskfile && WriteLog " [info] $instanceID $disk compress to $instanceBackdir dirname." || WriteLog " [error] $instanceID $disk compress error."
		fi
	done
	[ -f "$diskinfo" ] && cp -a $diskinfo $instanceBackdir

}

CleanData(){
	YesterDate=$(date -d "-1day" +%F)
	instanceBackdir="$BackupDir/$instanceID"
	DeleteList=$(find $instanceBackdir -name "*_$YesterDate*")
	for file in ${DeleteList[*]}
	do
		rm -f $file && WriteLog " [info] delete $file" || WriteLog " [error] delete $file failed."
	done
}


main(){
	AuthID &&\
	VMbackdir &&\
	VMinfo &&\
	BackDisk &&\
	CleanData
}

if [ "$#" == 1 ];then
	main
else
	echo "error: your must input VM instacnce ID" 1>&2
fi
