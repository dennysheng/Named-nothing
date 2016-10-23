#!/bin/bash
# ----------------------------------------------------------------------------
# Filename: Redis_instance_stastics.sh
# Revision: 1.0
# Auther: 盛况
# Date: 2016-10-20
# Description: [Redis 简版]脚本在任意机器运行，用于分析Redis实例运行状态。
# Description: 包括(1).读取Redis信息(2).入库(3).提取 三个模块
# Usage: 0 * * * * root /bin/bash /opt/dsheng/Redis_instance_stastics.sh  \
#       &> /dev/null
# Question: 
# Notes:        a).
# Notes:		b).
# Notes:		c).
# ----------------------------------------------------------------------------

# 创建日志函数
function log_append() {
	date_minutes=$(date +%y%m%d_%H:%M)
	date_seconds=$(date +%y%m%d_%H:%M:%S)
	echo ${date_seconds}
	if [ ! -d "/var/log/operations" ];
	then
		mkdir -p /var/log/operations
		touch ${log_path}/redis_instances_stastics.log
	fi
	log_path="/var/log/operations"
	log_file="${log_path}/redis_instances_stastics.log"
	echo ${log_path}
	echo ${log_file}
	#log_error_append=$(echo "${date_seconds}[ERROR]${error_message}" >> ${log_file})
	#log_info_append=$(echo "${date_seconds}[INFO]${info_message}" >> ${log_file})
}

# Redis初始化
function redis_init() {
	redis_host="192.168.5.21"
	which redis-cli
	if [ $? == 0 ];
	then
		echo "${date_seconds}[INFO]redis_init module:redis-cli command normal, \
		ready to get redis running stastics data." >> "${log_file}"
		#error_message='redis_init module:redis-cli command exist.'
		#log_info_append
		#exit 0
	else
		echo "${date_seconds}[ERROR]redis_init module:redis-cli command not found, \
		please login the server then input redis-cli to test." >> ${log_file}
		#info_message='redis_init module:redis-cli command not available.'
		#log_error_message
		exit 1
	fi
}

# 识别Redis实例身份的函数
function redis_instance_identify() {
	case "redis_instance_name" in
	'general')
		redis_instance_port='6379'
		redis_instance_auth='youdonothavetoknow'
	;;
	*)
		error_message='redis_instances_identify module:No such redis instance.'
		log_error_append
		exit 1
		;;
	esac
}

# 识别Redis实例身份的函数
function redis_instance_identify2() {
	redis_instance_port="6379"
	redis_instance_auth="youdonothavetoknow"
}

# 获取特定Redis实例的运行状态
function get_redis_status() {
	redis_parameter="$1"
	#redis-cli -h ${redis_host} -p ${redis_instance_port} -a ${redis_instance_auth} info | grep '$1' | awk -F':' '{print $2}'
	redis-cli -h ${redis_host} -p ${redis_instance_port} -a ${redis_instance_auth} info | grep ${redis_parameter} | awk -F: '{print $2}'
}

# 初始化MySQL数据库
function db_init() {
	db_host='mysql1'
	db_username='root'
	db_password='youdonothavetoknow'
	#mysql -u${db_host} -p${db_password} -h${db_host} -e "CREATE DATABASE OPERATIONS";
	target_db_name='OPERATIONS'
	target_table_name='t_redis_stastics_data'
}

# 将Redis实例状态入库
function set_redis_status() {
	insert_date=$(date +%Y-%m-%d\ %H:%M:%S)
	which redis-cli
	if [ $? == 0 ];
	then
		used_memory_human=$(redis-cli -h ${redis_host} -p ${redis_instance_port} -a ${redis_instance_auth} info | grep 'used_memory_human' | awk -F':' '{print $2}')
		#used_memory_human=$(get_redis_status used_memory_human)
		used_memory_peak_human=$(get_redis_status used_memory_peak_human)
		mem_fragmentation_ratio=$(get_redis_status mem_fragmentation_ratio)
		connected_clients=$(get_redis_status connected_clients)
		key_count=$(redis-cli -h ${redis_host} -p ${redis_instance_port} -a ${redis_instance_auth} dbsize | awk "{print $2}" )
		echo "used_memory_human is ${used_memory_human}"	
		echo "connected_clients is ${connected_clients}"	
		mysql -h${db_host} -e "insert into ${target_db_name}.${target_table_name} \
			(insert_date,redis_instances_name,redis_instances_host,\
			redis_instances_port,used_memory_human,used_memory_peak_human,\
			mem_fragmentation_ratio,connected_clients,key_count) values \
			('${insert_date}','general','${redis_host}','${redis_instance_port}',\
			'${used_memory_human}','${used_memory_peak_human}',\
			'${mem_fragmentation_ratio}','${connected_clients}','${key_count}');"
		if [ $? == 0 ];
		then
			echo "${date_seconds}[INFO]set_redis_status module:redis stastics data insert done!" >> ${log_file}
		else
			echo "${date_seconds}[ERROR]set_redis_status module:redis stastics data insert failed!" >> ${log_file}
			exit 1
		fi
	else
		echo "${date_seconds}[ERROR]set_redis_status module:redis stastics data get failed!" >> ${log_file}
		exit 1
	fi			
}

function main() {
	log_append && echo "log_append done"
	redis_init && echo "redis_init done"
	redis_instance_identify2 && echo "redis_instance_identify2 done"
	get_redis_status && echo "get_redis_status done"
	db_init && echo "db_init done"
	set_redis_status && echo "set_redis_status done"
}

main
