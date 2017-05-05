#/bin/bash

item=$(echo "ZRANGEBYSCORE taskserverstore -inf 999 withscores" | /usr/local/bin/redis-cli -h 192.168.1.212 |grep -v "convert"|grep -v null)
num=0
for n in $item
do
    if [ $n -gt 100 ] ;then
		((num=$num+1))
    fi
done
echo "$num"
