#!/usr/bin/bash
#
# Script to get the set of unique errors from log files for a new code version.
# Typically, this script should be run in integration sandbox:
# 1. After installation & activation of a new code version.
# 1. After running the integration & acceptance test scripts.
#
# Generates one output file containing the unique log records, stack traces 
# are removed. Stack traces are maintained in separate files with their ID 
# as file names. These output files should be version-controller for next
# release comparison.
#
# USAGE: bash get_unique_log_recs.sh <code-version>  <logs-dir|one-single-log-file> [<output-dir>]

# Function to remove the variables in a log record
# Assumption: Only 1st line with timestamp contains variable strings
function remove_variables_in_logrec() {
    op_str=''
    ip_arr
}

function proc_log_file_for_dupl_logrec() {
    f_name=$1
    curr_logrec=""
    while IFS= read -r ip_line; do
        if [[ $ip_line =~ ^\[[^]]*\] ]]; then
            
    done < $f_name
}
# START of main function
if [ $# -lt 2 ]; then
    echo "USAGE: bash get_unique_log_recs.sh <code-version> <logs-dir> [<output-dir>]"
    exit 1
fi
op_dir="unique_log_recs"
if [ $# -eq 3 ]; then
    op_dir=$3
fi
echo "... Output directory set to: $op_dir"
if [ -f $2 ]; then

elif [ -d $2 ]; then

fi

