#!/bin/bash
set -e

LOCAL_PWD=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OSVERSION=`uname`
ADMIN_USER=`whoami`
ADMIN_HOME=$(eval echo ~$ADMIN_USER)

init_log()
{
	if [ -f $LOCAL_PWD/log/end_$1.log ]; then
		exit 0
	fi

	logfile=rollout_$1.log
	rm -f $LOCAL_PWD/log/$logfile
}

start_log()
{
	if [ "$OSVERSION" == "Linux" ]; then
		T="$(date +%s%N)"
	else
		T="$(date +%s)"
	fi
}

end_step()
{
	local logfile=end_$1.log
	touch $LOCAL_PWD/log/$logfile
}

log()
{
	#duration
	if [ "$OSVERSION" == "Linux" ]; then
		T="$(($(date +%s%N)-T))"
		# seconds
		S="$((T/1000000000))"
		# milliseconds
		M="$((T/1000000))"
	else
		#must be OSX which doesn't have nano-seconds
		T="$(($(date +%s)-T))"
		S=$T
		M=0
	fi

	#this is done for steps that don't have id values
	if [ "$id" == "" ]; then
		id="1"
	else
		id=$(basename $i | awk -F '.' '{print $1}')
	fi

	tuples=$1
	log_status=$2
	if [ "$tuples" == "" ]; then
		tuples="0"
	fi

	if [ "$log_status" == "" ]; then
		log_status="success"
	fi

	printf "$id|$schema_name.$table_name|$tuples|$log_status|%02d:%02d:%02d.%03d\n" "$((S/3600%24))" "$((S/60%60))" "$((S%60))" "${M}" >> $LOCAL_PWD/log/$logfile
}

get_imp_details()
{
	#sets PARALLEL and IMP_HOST
	if [ -f $LOCAL_PWD/dn.txt ]; then
		local DN_COUNTER=$(cat $LOCAL_PWD/dn.txt | wc -l)
		local RANDOM_COUNTER=$(( ( RANDOM % $DN_COUNTER )  + 1 ))
		PARALLEL=$(($DN_COUNTER * $DSDGEN_THREADS_PER_NODE))

		i="0"
		for dn in $(cat $LOCAL_PWD/dn.txt); do
			i=$(($i + 1))
			if [ "$i" -eq "$RANDOM_COUNTER" ]; then
				IMP_HOST="$dn"
			fi
		done
	else
		echo "$PWD/dn.txt not found!"
		echo "Please enter all of the datanodes into this file and try again."
		exit 1
	fi
}
