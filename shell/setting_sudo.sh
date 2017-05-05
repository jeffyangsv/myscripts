#!/bin/bash
##################################################
#Name:        sudoer_look_auth.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "查看sudo用户的权限"
##################################################

auth_setting(){
	echo  "Default     logfile=/var/log/sudo.log" >> /etc/sudoers     #sudoer日志记录
	echo  "Defaults    loglinelen=0" >> /etc/sudoers		  #设置日志结果唯一行，方便统计
	visudo -c                                          		  #检查sudoers文件语法
	echo  "local2.debug     logfile=/var/log/sudo.log"  >>  /etc/rsyslog.conf 
	systemctl restart rsyslog.service
}
auth_add(){
	Username=$1
	Auth=$2
	echo "$Username   ALL=(root)  NOPASSWD:${Auth}"  >>  /etc/sudoers
}
auth_select(){
	echo "Sudo提权成功的行为审计:用户 命令"  
	#success=$(cat /var/log/sudo.log | grep sudo | grep -v failure | awk -F"=|:|" '{print $4,$9}')
	cat /var/log/sudo.log | grep sudo | egrep -v 'pam_unix' |awk -F"=|:|" '{print $4,$9}' | grep -v root
	
	echo "Sudo提权失败的用户:" 
	#failure=$(cat /var/log/sudo.log | grep sudo | grep failure | awk -F'=' '{print $8}')
	cat /var/log/sudo.log | grep sudo | grep failure | awk -F'=' '{print $8}'
}

main (){
	case $1 in
		set)
			auth_setting;
			;;
		add)
			auth_add  $2 $3;
			;;
		sel)
			auth_select;
			;;
		*)
			echo $"Usage: $0 (set|add user auth|sel)"			
		esac
}
main $1 $2 $3
