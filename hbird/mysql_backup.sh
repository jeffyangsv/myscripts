#backup.sh
#!/bin/sh
#on xtrabackup 2.4.12
# ��һ��ִ������ʱ���������Ƿ�����ȫ����,�����ȴ���һ��ȫ�ⱸ��
# �����ٴ���������ʱ��������ݽű��е��趨������֮ǰ��ȫ�����������ݽ�����������
# xikou@qq.com
# ��װxtrabackup2.4
# wget https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.12/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.12-1.el7.x86_64.rpm
# yum -y localinstall percona-xtrabackup-24-2.4.12-1.el7.x86_64.rpm

 
INNOBACKUPEX_PATH=innobackupex  #INNOBACKUPEX������
INNOBACKUPEXFULL=/usr/bin/$INNOBACKUPEX_PATH  #INNOBACKUPEX������·��
 
#mysqlĿ��������Լ��û���������
MYSQL_CMD="--host=172.19.196.53 --user=root --password=password --port=3306"  
 
MYSQL_UP=" --user=root --password='password' --port=3306 "  #mysqladmin���û���������
 
TMPLOG="/tmp/innobackupex.$$.log"
 
MY_CNF=/etc/my.cnf #mysql�������ļ�
 
MYSQL=/usr/bin/mysql
 
MYSQL_ADMIN=/usr/bin/mysqladmin
 
BACKUP_DIR=/data/backup/lxqb # ���ݵ���Ŀ¼

BACKUP_DBNAME=smartdatadb  #���ݵ����ݿ�
 
FULLBACKUP_DIR=$BACKUP_DIR/full # ȫ�ⱸ�ݵ�Ŀ¼
 
INCRBACKUP_DIR=$BACKUP_DIR/incre # �������ݵ�Ŀ¼
 
FULLBACKUP_INTERVAL=86400 # ȫ�ⱸ�ݵļ�����ڣ�ʱ�䣺��
 
KEEP_FULLBACKUP=1 # ���ٱ�������ȫ�ⱸ��
 
logfiledate=backup.`date +%Y%m%d%H%M`.txt
 
#��ʼʱ��
STARTED_TIME=`date +%s`
 
 
 
#############################################################################
 
# ��ʾ�����˳�
 
#############################################################################
 
error()
{
    echo "$1" 1>&2
    exit 1
}
 
 
 
# ���ִ�л���
 
if [ ! -x $INNOBACKUPEXFULL ]; then
  error "$INNOBACKUPEXFULLδ��װ��δ���ӵ�/usr/bin."
fi
 
 
 
if [ ! -d $BACKUP_DIR ]; then
  error "����Ŀ���ļ���:$BACKUP_DIR������."
fi
 
 
 
mysql_status=`netstat -nl | awk 'NR>2{if ($4 ~ /.*:3306/) {print "Yes";exit 0}}'`
 
if [ "$mysql_status" != "Yes" ];then
    error "MySQL û����������."
fi
 
 
 
 
 
if ! `echo 'exit' | $MYSQL -s $MYSQL_CMD` ; then
 error "�ṩ�����ݿ��û��������벻��ȷ!"
fi
 
 
 
# ���ݵ�ͷ����Ϣ
 
echo "----------------------------"
echo
echo "$0: MySQL���ݽű�"
echo "��ʼ��: `date +%F' '%T' '%w`"
echo
 
 
 
#�½�ȫ���Ͳ��챸�ݵ�Ŀ¼
 
mkdir -p $FULLBACKUP_DIR
mkdir -p $INCRBACKUP_DIR
 
 
 
#�������µ���ȫ����
LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
 
 
 
# ��������޸ĵ����±���ʱ��
 
LATEST_FULL_BACKUP_CREATED_TIME=`stat -c %Y $FULLBACKUP_DIR/$LATEST_FULL_BACKUP`
 
 
#���ȫ����Ч�����������ݷ���ִ����ȫ����
if [ "$LATEST_FULL_BACKUP" -a `expr $LATEST_FULL_BACKUP_CREATED_TIME + $FULLBACKUP_INTERVAL + 5` -ge $STARTED_TIME ] ; then
	# ������µ�ȫ��δ�����������µ�ȫ���ļ�����������������Ŀ¼���½�Ŀ¼
	echo -e "��ȫ����$LATEST_FULL_BACKUPδ����,������$LATEST_FULL_BACKUP������Ϊ�������ݻ���Ŀ¼��"
	echo "					   "
	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP
	mkdir -p $NEW_INCRDIR
 
	# �������µ����������Ƿ����.ָ��һ�����ݵ�·����Ϊ�������ݵĻ���
	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`
		if [ ! $LATEST_INCR_BACKUP ] ; then
			INCRBASEDIR=$FULLBACKUP_DIR/$LATEST_FULL_BACKUP
			echo -e "�������ݽ���$INCRBASEDIR��Ϊ���ݻ���Ŀ¼"
			echo "					   "
		else
			INCRBASEDIR=$INCRBACKUP_DIR/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}
			echo -e "�������ݽ���$INCRBASEDIR��Ϊ���ݻ���Ŀ¼"
			echo "					   "
		fi
 
	echo "ʹ��$INCRBASEDIR��Ϊ���������������ݵĻ���Ŀ¼."
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF --use-memory=2G $MYSQL_CMD --databases=$BACKUP_DBNAME --incremental $NEW_INCRDIR --incremental-basedir $INCRBASEDIR > $TMPLOG 2>&1
 
	#����һ�ݱ��ݵ���ϸ��־
 
	cat $TMPLOG>$BACKUP_DIR/$logfiledate
 
	if [ -z "`tail -1 $TMPLOG | grep 'completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX����ִ��ʧ��:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH���� ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi
 
	THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG
 
 
	echo -n "���ݿ�ɹ����ݵ�:$THISBACKUP"
	echo
 
	# ��ʾӦ�ñ����ı����ļ����
 
	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
 
	NEW_INCRDIR=$INCRBACKUP_DIR/$LATEST_FULL_BACKUP
 
	LATEST_INCR_BACKUP=`find $NEW_INCRDIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n"  | sort -nr | head -1`
 
	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}
 
	RES_INCRE_BACKUP=`dirname ${INCRBACKUP_DIR}/${LATEST_FULL_BACKUP}/${LATEST_INCR_BACKUP}`
 
	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #��ɫ
	echo -e "���뱣��$KEEP_FULLBACKUP��ȫ��--��ȫ��${RES_FULL_BACKUP}��${RES_INCRE_BACKUP}Ŀ¼��������������."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #��ɫ
	echo
 
 
 
else
	echo  "*********************************"
	echo -e "����ִ��ȫ�µ���ȫ����...���Ե�..."
	echo  "*********************************"
	$INNOBACKUPEXFULL --defaults-file=$MY_CNF  --use-memory=2G  $MYSQL_CMD --databases=$BACKUP_DBNAME $FULLBACKUP_DIR > $TMPLOG 2>&1 
	#����һ�ݱ��ݵ���ϸ��־
 
	cat $TMPLOG>$BACKUP_DIR/$logfiledate
 
 
	if [ -z "`tail -1 $TMPLOG | grep 'completed OK!'`" ] ; then
	 echo "$INNOBACKUPEX����ִ��ʧ��:"; echo
	 echo -e "---------- $INNOBACKUPEX_PATH���� ----------"
	 cat $TMPLOG
	 rm -f $TMPLOG
	 exit 1
	fi
 
	 
	THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPLOG`
	rm -f $TMPLOG
 
	echo -n "���ݿ�ɹ����ݵ�:$THISBACKUP"
	echo
 
	# ��ʾӦ�ñ����ı����ļ����
 
	LATEST_FULL_BACKUP=`find $FULLBACKUP_DIR -mindepth 1 -maxdepth 1 -type d -printf "%P\n" | sort -nr | head -1`
 
	RES_FULL_BACKUP=${FULLBACKUP_DIR}/${LATEST_FULL_BACKUP}
 
	echo
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #��ɫ
	echo -e "����������,���뱣��$KEEP_FULLBACKUP��ȫ����ȫ��${RES_FULL_BACKUP}."
	echo -e '\e[31m NOTE:---------------------------------------------------------------------------------.\e[m' #��ɫ
	echo
 
fi
 
 
 
 
 
 
#ɾ�����ڵ�ȫ��
 
echo -e "find expire backup file...........waiting........."
echo -e "Ѱ�ҹ���(����5��)��ȫ���ļ���ɾ��">>$BACKUP_DIR/$logfiledate
for efile in $(/usr/bin/find $FULLBACKUP_DIR/ -mtime +4)
do
	if [ -d ${efile} ]; then
	rm -rf "${efile}"
	echo -e "ɾ������ȫ���ļ�:${efile}" >>$BACKUP_DIR/$logfiledate
	elif [ -f ${efile} ]; then
	rm -rf "${efile}"
	echo -e "ɾ������ȫ���ļ�:${efile}" >>$BACKUP_DIR/$logfiledate
	fi;
	
done
if [ $? -eq "0" ];then
   echo
   echo -e "δ�ҵ�����ɾ���Ĺ���ȫ���ļ�"
fi
echo
echo "�����: `date +%F' '%T' '%w`"
exit 0

