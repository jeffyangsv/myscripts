#!/usr/bin/expexct
##################################################
#Name:        fenfa_except.sh
#Version:     v1.0
#Create_Date：2016-10-10
#Author:      GuoLikai(glk73748196@sina.com)
#Description: "免交互分发文件到服务器"
##################################################

if { $argv != 2 } {
   send_user "Usage:expect scp-expect.exp file host\n"
   exit
}
#定义变量
set file [lindex $argv 0]
set host [lindex $argv 1]
set passwd "123456"
#spawn scp /etc/hosts glk888@192.168.4.71:/etc/hosts
spawn ssh-copy-id -i $file  glk888@$host
expect {
    "yes/no"    {send "yes\r";exp_continue}
    "*password" {send "$passwd\r"}
}
expect eof
exit -onexit {
    send_user "expect say good bay to you!\n"
}

