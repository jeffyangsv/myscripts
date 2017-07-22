#!/bin/bash
echo "Mariadb 数据库密码初始化"
/usr/bin/expect <<-EOF
set time 30
spawn mysql -u root -p
expect {
    "Enter password:" { send "\r";exp_continue}
    "MariaDB" {send " SET PASSWORD FOR 'root'@'localhost' = PASSWORD('123456');\r";}
}
interact
#expect eof  #留在expect终端
EOF
echo "------------------------------------------Mariadb 数据库密码初始化Ok----------------------------------------"
