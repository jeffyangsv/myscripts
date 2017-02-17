#/bin/bash

m=$1
method=(LLEN)
for n in ${method[*]}
do
     echo "$n $m" |/usr/local/bin/redis-cli -h 192.168.1.212|grep -v "integer"
done
