# Function to compare two GMT timestamps strings like "2022-01-16 04:12:51.312"
# Returns -1 if "$1 $" < "$3 $4", 0 if equal and 1 if greater
ret_ts_diff=0
function cmp_timestamps_using_date_cmd() {
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

# Function to return regex to match two timestamps
# Some test cases below: 
# 1. 09:19:05,09:45:01 => 09:[1-4][0-9]:
# 2. 09:19:05,10:05:01 => (09|10):[0-5][0-9]:
# 3. 10:45:48,15:23:33 => 1[0-5]:[0-5][0-9]:[0-5]
# NOT USIng this since a bit complex
ret_regex=''
function get_regex_from_timestamps() {
    ts_1="$1"
    ts_2="$2"
    first_diff_char=$(cmp <( echo "$ts_1" ) <( echo "$ts_2" ) | cut -d " " -f 5 | tr -d ",")
    #echo ${ts_1:0:$((first_diff_char-1))}
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
                echo "...... Checking if $rec_ts > $1 - $ret_ts_diff"
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
                echo "...... Checking if $rec_ts <= $2 - $ret_ts_diff"
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
