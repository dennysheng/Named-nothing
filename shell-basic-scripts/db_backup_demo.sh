#!/bin/bash
# ----------------------------------------------------------------------------
# Filename: db_backup.sh
# Revision: 1.0
# Auther: 盛况
# Date: 2016-10-19
# Description: 脚本在任意单台机器运行，用于备份数据库数据
# Usage: 0 3 * * * root /bin/bash /opt/dsheng/db_backup.sh  \
#       &> /tmp/db_backup.log
# Question: 
# Notes:        a).每天通过crontab 03:00 运行一次。
# Notes:	b).保留三个备份，超过三天的文件会被认为是'old_backup_files'\
# Notes:	c).下一版本可能需要将备份文件加密，传输下来再解密。 
# ----------------------------------------------------------------------------

backup_file_path="/data/backup/db_backup"
log_file="/tmp/db_backup.log"
old_backup_files=$(find ${backup_file_path}/ -name test_db_backup* -mtime +3)
old_backup_files_count=$(ls -lht ${old_backup_files} | wc -l )

db_username="root"
db_password="youdon'thavetoknow"
db_host="mysql2"

[ -d ${backup_file_path} ] || mkdir -p ${backup_file_path} \
&& chmod a+w ${backup_file_path}
[ -e ${log_file} ] || touch ${log_file}

which mysqldump
if [ $? == 0 ];
then
	mysqldump -u${db_username} -p${db_password} -h${db_host} \
	--all-databases --single-transaction --event \
	> ${backup_file_path}/test_db_backup_$(date +%Y%m%d_%H:%M).sql
	if [ $? == 0 ];
	then
		echo "$(date +%Y%m%d_%H:%M:%S)[INFO]MySQL data backup done! \
	Backup file path: ${backup_file_path}" >> ${log_file}
	else
		echo "$(date +%Y%m%d_%H:%M:%S)[ERROR]mysqldump failed! \
		please check and make test." >> ${log_file}
	fi
else
	echo "$(date +%Y%m%d_%H:%M:%S)[ERROR]No mysqldump command found." \
	>> ${log_file}
	exit 1
fi

# 删除超过三天的备份文件
if [ ${old_backup_files_count} -gt 3 ];
then
	echo "$(date +%Y%m%d_%H:%M:%S)[INFO]Here are old backup files need to be removed." \
	>> ${log_file}
	echo "$(date +%Y%m%d_%H:%M:%S)[INFO]Removing old backup files: ${old_backup_files}..."
	rm -rf ${old_backup_files}
	echo "$(date +%Y%m%d_%H:%M:%S)[INFO]Old backup file(s) removed done!" >> ${log_file}
else
	echo "$(date +%Y%m%d_%H:%M:%S)[INFO]Only serveral backup files, no need to be removed." \
	>> ${log_file}
fi
