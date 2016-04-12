#!/bin/bash

set -e

PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $PWD/../functions.sh
source $PWD/../tpcds-env.sh

session_id=$1

if [ "$session_id" == "" ]; then
	echo "Error: you must provide the session id as a parameter."
	echo "Example: ./test.sh 3"
	echo "This will execute the session 3 queries."
	exit 1
fi

step=testing_$session_id

init_log $step

#call external function to get IMP_HOST
get_imp_details

if [ "$SQL_VERSION" != "tpcds" ]; then
	sql_dir=$PWD/$SQL_VERSION/$session_id
else
	sql_dir=$PWD/$session_id
	#going from 1 base to 0 base
	tpcds_id=$((session_id-1))
	tpcds_query_name="query_""$tpcds_id"".sql"
	query_id=1
	for p in $(seq 1 99); do
		q=$(printf %02d $query_id)
		template_filename=query$p.tpl
		start_position=""
		end_position=""
		for pos in $(grep -n $template_filename $sql_dir/$tpcds_query_name | awk -F ':' '{print $1}'); do
			if [ "$start_position" == "" ]; then
				start_position=$pos
			else
				end_position=$pos
			fi
		done

		#Impala can't handle the last lining in a SQL file being a comment so remove.
		end_position=$(($end_position-1))

		#get the query number (the order of query execution) generated by dsqgen
		file_id=$(sed -n "$start_position","$start_position"p $sql_dir/$tpcds_query_name | awk -F ' ' '{print $4}')
		file_id=$(($file_id+100))
		filename=$file_id.query.$q.sql
		sed -n "$start_position","$end_position"p $sql_dir/$tpcds_query_name > $sql_dir/$filename
		query_id=$(($query_id + 1))
		echo "Completed: $sql_dir/$filename"
	done
	echo "rm -f $sql_dir/query_*.sql"
	rm -f $sql_dir/$tpcds_query_name
fi

tuples="0"
for i in $(ls $sql_dir/*.sql); do

	start_log
	id=$i
	schema_name=$session_id
	table_name=$(basename $i | awk -F '.' '{print $3}')

	run_query="1"
	oom_count="0"
	while [ "$run_query" -eq "1" ]; do
		echo "impala-shell -i $IMP_HOST -d $TPCDS_DBNAME -f $i --quiet -c"
		impala-shell -i $IMP_HOST -d $TPCDS_DBNAME -f $i --quiet -c > /tmp/impala_shell_$session_id.log 2>&1 

		error_count=$(grep ERROR /tmp/impala_shell_$session_id.log | wc -l)
		oom_count=$(grep Memory /tmp/impala_shell_$session_id.log | wc -l)

		if [ "$SQL_VERSION" == "tpcds" ]; then
			#tpc-ds queries will fail because Impala doesn't support the syntax.  Continue with these queries and don't retry
			if [ "$oom_count" -gt "0" ]; then
				grep Memory /tmp/impala_shell_$session_id.log
				tuples="0"
			else
				if [ "$error_count" -gt "0" ]; then
					grep ERROR /tmp/impala_shell_$session_id.log 
					tuples="0"
				else
					tuples=$(cat /tmp/impala_shell_$session_id.log | wc -l)
				fi
			fi
			run_query="0"
			log $tuples
		else
			#running the Cloudera imp queries so retry on failed	
			if [ "$oom_count" -gt "0" ]; then
				#query ran but ran out of memory.  Don't retry
				grep Memory /tmp/impala_shell_$session_id.log
				tuples="0"
				run_query="0"
				log $tuples
			else
				if [ "$error_count" -gt "0" ]; then
					# there was an error which was likely due to a connect timeout.  wait 5 seconds and try again
					grep ERROR /tmp/impala_shell_$session_id.log 
					run_query="1"
					sleep 5
				else
					tuples=$(cat /tmp/impala_shell_$session_id.log | wc -l)
					run_query="0"
					log $tuples
				fi
			fi
		fi
	done

done

end_step $step
