#!/bin/sh
# 基于xtrabackup程序
source /etc/profile

NAME=mariadb_backup
PORT=3308
IP=localhost
MAILUSER=sa@yanxiu.com
DBUSER=backup
DBPASSWORD='89#dA321i'
TODAY=$(date +'%Y-%m-%d')
BACKUPDIR=/App/backup/mariadb/$TODAY
BACKUPFILE=$BACKUPDIR/${NAME}.tgz
LOGSDIR=/App/backup/logs
LOGFILE=$LOGSDIR/mariadb_${PORT}.$TODAY.log
SOCKET=/tmp/mariadb_${PORT}.sock
MYCNF=/App/conf/OPS/mariadb_${PORT}/my.cnf

test -d $BACKUPDIR || mkdir -p $BACKUPDIR
test -d $LOGSDIR || mkdir -p $LOGSDIR
test -d $STORDIR || mkdir -p $STORDIR
find $(dirname $BACKUPDIR) -maxdepth 1 -type d -mtime +1 -exec rm -rf {} \;
find $LOGSDIR -type f -mtime +60 -exec rm -rf {} \;


DATADIR=$(mysql -S$SOCKET -u$DBUSER -p$DBPASSWORD -e "SHOW VARIABLES LIKE 'datadir'" | grep 'datadir' | awk '{print $2}')
SLOWLOG=$(mysql -S$SOCKET -u$DBUSER -p$DBPASSWORD -e "SHOW VARIABLES LIKE 'slow_query_log_file'" | grep 'slow_query_log_file' | awk '{print $2}')
mv ${DATADIR}$SLOWLOG ${DATADIR}slow.$TODAY.log
mysqladmin -S$SOCKET -u$DBUSER -p$DBPASSWORD flush-logs

BACKUP="innobackupex --defaults-file=$MYCNF  --no-timestamp --no-version-check --parallel=8 --safe-slave-backup --slave-info --user $DBUSER --password $DBPASSWORD --stream=tar"
$BACKUP $BACKUPDIR 2>$LOGFILE | gzip 1>$BACKUPFILE

if [ $? -eq 0 ]; then
    echo "备份成功" | tee -a $LOGFILE
    FAILFLAG=0
else
    echo "备份失败" | tee -a $LOGFILE
    FAILFLAG=1
fi

if [ $FAILFLAG -eq 1 ]; then
    cat $LOGFILE | mutt -s "$NAME $IP MySQL数据库备份" $MAILUSER
fi
