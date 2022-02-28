#!/usr/bin/bash
#
# Script to get an sorted log of entries specific to a customer in a particular date
#
# USAGE: bash scripts/get_sorted_logs_for_customer_n_date.sh <Logs-root-dir> cust:<Customer-UUID>|sess:<Session-ID> <Date>
# 
# Example usages:
# 1. scripts/get_sorted_logs_for_customer_n_date.sh cust:74D958E9-D682-49AB-BF7E-3F1943EA53BC 20220126
# 2. scripts/get_sorted_logs_for_customer_n_date.sh sess:ZIk5xwdgdR 20220126

# Function to compare two GMT timestamps strings like "2022-01-16 04:12:51.312"
# Returns -1 if "$1 $" < "$3 $4", 0 if equal and 1 if greater
ret_ts_diff=0
function cmp_timestamps() {
	ts_1=$(date --date="$1" +%s)
	ts_2=$(date --date="$2" +%s)
	ts_diff=$(( ts_1 - ts_2 ))
	if [[ $ts_diff -lt 0 ]]; then
		time_diff=-1
	elif [[ $ts_diff -eq 0 ]]; then
		time_diff=0
	else
		time_diff=1
	fi
	if [[ $ts_diff -le 0 ]]; then
		ret_ts_diff=-1
	elif [[ $ts_diff -ge 0 ]]; then
		ret_ts_diff=1
	fi
}

# Function to compare dates by comparing just hour & min fields
# Input dates are of the form: 2022-01-16 04:12:51.312
ret_ts_diff=0
function chk_if_time_less_than() {
    arr1=( $1 )
    arr2=( $2 )
	arr1_time=${arr1[1]}
	arr2_time=${arr2[1]}
    time_arr1=( ${arr1_time//:/ } )
    time_arr2=( ${arr2_time//:/ } )
    hr_diff=$(( 10#${time_arr1[0]} - 10#${time_arr2[0]} ))
    min_diff=$(( 10#${time_arr1[1]} - 10#${time_arr2[1]} ))
    t_sec1=${time_arr1[2]%.*}
    t_sec2=${time_arr2[2]%.*}
    sec_diff=$(( 10#${t_sec1} - 10#${t_sec2} ))
    if [ $hr_diff -lt 0 ]; then
        ret_ts_diff=1
    elif [ $hr_diff -eq 0 ] && [ $min_diff -lt 0 ]; then
        ret_ts_diff=1
    elif [ $hr_diff -eq 0 ] && [ $min_diff -eq 0 ] && [ $sec_diff -le 0 ]; then
        ret_ts_diff=1
    else
        ret_ts_diff=0
    fi
}

# Function to filter log files of jobs between start & end timestamps
# Params: timestamp_1, timestamp_2, log_file_name, date (2022-01-26)
function get_log_entries_between() {
	echo "... In get_log_entries_between(): $1 $2 $3 $4"
    op_gate=0
    in_last_rec=0
	while read -r ip_log_rec; do
        if [ $op_gate -eq 0 ] && [ $in_last_rec -eq 0 ]; then
            if [[ "$ip_log_rec" =~ ^\[$4[[:space:]][0-9:]+ ]]; then
                temp_str="${ip_log_rec%% GMT]*}"
                rec_ts="${temp_str#[}"
                if [[ "$4" != "${rec_ts%% *}" ]]; then
                    echo "... First rec date is not same as input, breaking ..."
                    break
                fi
                chk_if_time_less_than "$1" "$rec_ts"
                #echo "...... Checking if $rec_ts > $1 - $ret_ts_diff"
                if [ $ret_ts_diff -eq 1 ]; then
                    op_gate=1
                    echo "$ip_log_rec" >>"./temp_dir1/${3##*/}"
                fi
            fi
            continue
        fi
        if [ $op_gate -eq 1 ] && [ $in_last_rec -eq 0 ]; then
            if [[ "$ip_log_rec" =~ ^\[$4[[:space:]][0-9:]+ ]]; then
                echo "$ip_log_rec" >>"./temp_dir1/${3##*/}"
                temp_str="${ip_log_rec%% GMT]*}"
                rec_ts="${temp_str#[}"
                chk_if_time_less_than "$rec_ts" "$2"
                #echo "...... Checking if $rec_ts <= $2 - $ret_ts_diff"
                if [ $ret_ts_diff -eq 0 ]; then
                    echo "...... Breaking from loop since $rec_ts > $2 - setting in_last_rec to 1"
                    op_gate=0
                    in_last_rec=1
                fi
            else
                # Handle lines which do not start with timestamp
                echo "$ip_log_rec" >>"./temp_dir1/${3##*/}"
            fi
            continue
        fi
        #This could be last record  with multiple lines, print those
        if [ $op_gate -eq 0 ] && [ $in_last_rec -eq 1 ]; then
		    if [[ "$ip_log_rec" =~ ^\[$4[[:space:]][0-9:]+ ]]; then
                echo "...... Breaking from loop since $rec_ts > $2"
                break
            else
                echo "$ip_log_rec" >>"./temp_dir1/${3##*/}"
            fi
        fi
		# If record timestamp in-between the two i/p timestamps, print
		# if [[ $retv_1 -eq -1 ]] ;then
		#  	if [[ $ret_ts_diff -eq -1 ]]; then
		# 		echo "$ip_log_rec" >>"./temp_dir1/${3##*/}"
		# 	else
		# 		echo "...... Breaking from loop since $rec_ts > $2" 
		# 		break
		# 	fi
		# fi
	done < "$3"
}

# Function to filter log records on a given date by session ID
function filter_logs_by_session() {
	log_d="$1"
	sess_id="$2"
	ip_date=$3
	#echo "... In filter_logs_by_session(): $log_d , $sess_id , $ip_date"
	#grep -l -m1 "|$sess_id " $log_d/*${ip_date}.log
	ip_date_s="${ip_date:0:4}-${ip_date:4:2}-${ip_date:6:2}"
	while IFS= read -r log_file; do
        curr_log_fname="${log_file##*/}"
		echo "...... Processing $curr_log_fname"
        gawk -v s_val="\\\\|$sess_id " -v f="^\\\\[${ip_date_s}.*GMT\\\\]" \
            -f ./scripts/xtrct_recs_sess.awk \
            $log_file >./temp_dir0/${sess_id}-${curr_log_fname%%.log}.log
    done < <(grep -l -m1 "|$sess_id " $log_d/*${ip_date}.log)
#		gawk -v f="$ts_pat" -v s="$sess_pat" '
#            BEGIN {print f >"/dev/stderr";print s >"/dev/srderr";}
#            ($0 ~ f) {
#				if ($0 ~ s) {flag=1} else {flag=0}
#				}
#			flag' $log_file >./temp_dir0/${ip_sess_id}-${curr_log_fname%%.log}.log 
#	done < <(ls $log_d/*${ip_date}.log)
	echo "+++++++ End of func filter_logs_by_session():"
}

# START of main program
if [[ $# -lt 3 ]]; then
	echo "USAGE: bash scripts/get_sorted_logs_for_customer_n_date.sh <Logs-root-dir> cust:<Customer-UUID>|sess:<Session-ID> <Date>"
	exit 1
fi
# First get the unique session IDs for this customer on this date
log_dir=$1
ip_date=$3
ip_date_s="${ip_date:0:4}-${ip_date:4:2}-${ip_date:6:2}"
ip_date_p1=$(date +%Y-%m-%d -d "$ip_date_s + 1 day")
ip_key="${2#*:}"
key_pfx="${2%%:*}"
mkdir -p ./op_sess_logs_${ip_date}_$ip_key
mkdir -p ./temp_dir0
mkdir -p ./temp_dir1
mkdir -p ./temp_gunzip
if [[ "$key_pfx" == "cust" ]]; then
	while IFS= read -r ip_sess_id ; do
		filter_logs_by_session "$log_dir" "$ip_sess_id" "$ip_date"
		echo "... Found $(ls temp_dir0/*.log|wc -l) log files with sessiod id: $ip_sess_id"
		#Merge the already sorted files, using key as numeric characters of [2022-01-27 09:29:32.921 GMT]
		echo "........ Going to merge-sort these files into one timestamp sorted file"
		sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24 ./temp_dir0/${ip_sess_id}-*.log >./op_sess_logs_${ip_date}_${ip_key}/${ip_sess_id}.log
		rm ./temp_dir0/*.log

		# Filter the log files of jobs & bring in those entries for each session start & end timestamps
		tmp_str=$(tac ./op_sess_logs_${ip_date}_${ip_key}/${ip_sess_id}.log|grep -m1 -E -o "^\[$ip_date_s [^ ]*")
		end_ts="${tmp_str#[}"
		tmp_str=$(grep -m1 -E -o "^\[$ip_date_s [^ ]*" ./op_sess_logs_${ip_date}_${ip_key}/${ip_sess_id}.log)
		start_ts="${tmp_str#[}"
		while IFS= read -r job_log_file ; do
			get_log_entries_between "$start_ts" "$end_ts" "$job_log_file" "$ip_date_s"
		done < <(find $log_dir/jobs/ -name '*.log' -newerct "$ip_date_s" ! -newerct "$ip_date_p1")
		while IFS= read -r job_log_file ; do
            log_fname=${job_log_file##*/}
            tmp_str2=${log_fname%.gz}
            if [ ${#tmp_str2} -ne ${#log_fname} ]; then
                gunzip -c "$job_log_file" >temp_gunzip/$tmp_str2
                c_job_log_file="./temp_gunzip/$tmp_str2"
            else
                c_job_log_file="$job_log_file"
            fi
			get_log_entries_between "$start_ts" "$end_ts" "$c_job_log_file" "$ip_date_s"
		done < <(find $log_dir -name jobs*$ip_date*.*)
		sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24 ./temp_dir1/*.log >./op_sess_logs_${ip_date}_${ip_key}/jobs_${ip_sess_id}.log
		# Merge in the jobs log records into front-end records
		sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24  ./op_sess_logs_${ip_date}_${ip_key}/${ip_sess_id}.log ./op_sess_logs_${ip_date}_${ip_key}/jobs_${ip_sess_id}.log >./op_sess_logs_${ip_date}_${ip_key}/${ip_sess_id}_with_jobs.log
		rm ./temp_dir1/*.log
	done < <(grep -E "^\[$ip_date_s\s.*\sGMT\].*${ip_key}" ${log_dir}/*-${ip_date}.log|sed -nE 's%.*(PipelineCall|OnRequest)\|([^ ]+) .*%\2%p'|sort -n|uniq) 
elif [[ "$key_pfx" == "sess" ]]; then
	filter_logs_by_session "$log_dir" "$ip_key" "$ip_date"
	echo "... Found $(ls temp_dir0/*.log|wc -l) log files with sessiod id: $ip_key"
	#Merge the already sorted files, using key as numeric characters of [2022-01-27 09:29:32.921 GMT]
	echo "........ Going to merge-sort these files into one timestamp sorted file"
	sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24 ./temp_dir0/${ip_key}-*.log >./op_sess_logs_${ip_date}_${ip_key}/${ip_key}.log
	#rm ./temp_dir0/*.log

	# Filter the log files of jobs & bring in those entries for each session start & end timestamps
	tmp_str=$(tac ./op_sess_logs_${ip_date}_${ip_key}/${ip_key}.log|grep -m1 -E -o "^\[$ip_date_s [^ ]*")
	end_ts="${tmp_str#[}"
	tmp_str=$(grep -m1 -E -o "^\[$ip_date_s [^ ]*" ./op_sess_logs_${ip_date}_${ip_key}/${ip_key}.log)
	start_ts="${tmp_str#[}"
	echo "...... Session logs: start-time: $start_ts, end-time: $end_ts"
	while IFS= read -r job_log_file ; do
		get_log_entries_between "$start_ts" "$end_ts" "$job_log_file" "$ip_date_s"
	done < <(find ${log_dir%%/*}/jobs/ -name '*.log' -newerct "$ip_date_s" ! -newerct "$ip_date_p1")
	echo "... Completed processing older job logs, starting newer ones ..."
	while IFS= read -r job_log_file ; do
        log_fname=${job_log_file##*/}
        tmp_str2=${log_fname%.gz}
        if [ ${#tmp_str2} -ne ${#log_fname} ]; then
            gunzip -c "$job_log_file" >temp_gunzip/$tmp_str2
            c_job_log_file="./temp_gunzip/$tmp_str2"
        else
            c_job_log_file="$job_log_file"
        fi
		echo "...... Processing job file: $job_log_file"
		get_log_entries_between "$start_ts" "$end_ts" "$c_job_log_file" "$ip_date_s"
	done < <(find $log_dir -name jobs*$ip_date*.*)
	#done < <(ls ${log_dir%%/*}/jobs*$ip_date.log)
	sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24 ./temp_dir1/*.log >./op_sess_logs_${ip_date}_${ip_key}/jobs_${ip_key}.log
	# Merge in the jobs log records into front-end records
	sort -nbms -k1.2,1.5 -k1.7,1.8 -k1.10,1.11 -k1.13,1.14 -k1.16,1.17 -k1.19,1.20 -k1.22,1.24  ./op_sess_logs_${ip_date}_${ip_key}/${ip_key}.log ./op_sess_logs_${ip_date}_${ip_key}/jobs_${ip_key}.log >./op_sess_logs_${ip_date}_${ip_key}/${ip_key}_with_jobs.log
	#rm ./temp_dir1/*.log
fi
#rm -rf ./temp_dir0
#rm -rf ./temp_dir1
