#!/bin/bash
set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source $PWD/../tpcds-env.sh

remove_old_files()
{
	echo "hdfs dfs -rm -r -f -skipTrash ${FLATFILE_HDFS_REPORTS}"
	hdfs dfs -rm -r -f -skipTrash ${FLATFILE_HDFS_REPORTS}
}

create_new_directories()
{
	echo "hdfs dfs -mkdir ${FLATFILE_HDFS_REPORTS}'"
	hdfs dfs -mkdir ${FLATFILE_HDFS_REPORTS}

	for t in sql; do
		echo "hdfs dfs -mkdir ${FLATFILE_HDFS_REPORTS}/$t"
		hdfs dfs -mkdir ${FLATFILE_HDFS_REPORTS}/$t
	done

	echo "hdfs dfs -chmod -R 777 ${FLATFILE_HDFS_REPORTS}"
	hdfs dfs -chmod -R 777 ${FLATFILE_HDFS_REPORTS}

}

put_data()
{
	for t in sql; do
		TARGET_PATH=$FLATFILE_HDFS_REPORTS"/"$t
		echo "hdfs dfs -put $PWD/../log/rollout_$t.log $TARGET_PATH"
		hdfs dfs -put $PWD/../log/rollout_$t.log $TARGET_PATH
	done
}

create_tables()
{
	for i in $(ls $PWD/*.sql | grep -v report.sql); do
		id=$(basename $i | awk -F '.' '{print $1}')

		if [ "$id" == "00" ]; then
			echo "impala-shell -i $IMP_HOST -d default -f $i"
			impala-shell -i $IMP_HOST -d default -f $i
		else
			echo "impala-shell -i $IMP_HOST -d testing -f $i"
			impala-shell -i $IMP_HOST -d testing -f $i
		fi
	done
}

view_reports()
{
	for i in $(ls $PWD/*.sql | grep report); do
		echo "impala-shell -i $IMP_HOST -d testing -f $i"
		impala-shell -i $IMP_HOST -d testing -f $i
	done
}

#call external function to get IMP_HOST
get_imp_details

remove_old_files
create_new_directories
put_data
create_tables
view_reports
