#!/bin/bash

function usage_start_analysis {
   echo "" >&2
   echo "Usage: $0 [-v] [-s start time (HH:MM:SS)] [-e end time (HH:MM:SS)] [-i sample interval (in whole seconds)] [-n sample number]" >&2
   echo "  -v : prints script version" >&2
   echo "  -s : start time (HH:MM:SS) of analysis" >&2
   echo "  -e : end time (HH:MM:SS) of analysis" >&2
   echo "  -i : sample interval - time between each measurement (in seconds, positive integer only)" >&2
   echo "  -n : sample number - number of samples in each analyzed batch (positive integer only)" >&2
   echo "" >&2
   exit 1
}

# Initialize the index
OPTIND=1

# Uncomment for getopts errors
#OPTERR=0

###################################################################
#
# Some stuff for argument checking
#
###################################################################
# All colonned arguments require a value and in this case
# all colonned arguments are required - so count them
# Change this when adding extra arguments.
getopts_frmt=vs:e:i:n:

# Remove all but the colons - use this for a test later on
colons=${getopts_frmt//[^:]}

# Now multiply the number of colons by 2 - OPTIND counts the values
opt_count=$(( ${#colons} * 2 ))

while getopts $getopts_frmt OPT; do
    case "$OPT" in
        v)
           echo "`basename $0` version 0.1"
           exit 0
           ;;
        s)
           start_epoch=$(date --date=${OPTARG} +%s 2> /dev/null)
           if [[ $? -ne 0 ]];then
              echo "Start time \"${OPTARG}\" is not formatted correctly!" >&2
              exit 1
           fi
           ;;
        e)
           end_epoch=$(date --date=${OPTARG} +%s 2> /dev/null)
           if [[ $? -ne 0 ]];then
              echo "End time \"${OPTARG}\" is not formatted correctly!" >&2
              exit 1
           fi
           ;;
        i)
           # Integer test
           if [[ ${OPTARG} =~ ^[+]?[1-9][0-9]*$ ]]; then
              sample_interval=${OPTARG//[^0-9]}
           else
              echo "sample interval seconds \"${OPTARG}\" is not a positive integer value" >&2
              exit 1
           fi
           ;;
        n)
           # Integer test
           if [[ ${OPTARG} =~ ^[+]?[1-9][0-9]*$ ]]; then
              sample_number=${OPTARG//[^0-9]}
           else
              echo "sample number \"${OPTARG}\" is not a positive integer value" >&2
              exit 1
           fi
           ;;
        \?)
           # getopts issues an error message
           usage_start_analysis
           ;;
    esac
done

###################################################################
#
# Check the number of args - none should be omitted in this case
#
###################################################################
if [[ $OPTIND -le $opt_count ]]; then
   echo "${0}: missing arguments!" >&2
   usage_start_analysis
fi

###################################################################
#
# Some stuff for date checking
#
###################################################################
# Check the start and end times
current_epoch=$(date +%s)
if [[ $start_epoch -lt $current_epoch ]]; then
   echo "Start date $(date -d @$start_epoch) has already passed!" >&2
   exit 1
fi

# Check the end time is later than the start time
if [[ $end_epoch -lt $start_epoch ]]; then
   echo "End date $(date -d @$end_epoch) is earlier than the start date $(date -d @$start_epoch)!" >&2
   exit 1
fi

###################################################################
#
# Sort out the timings
#
###################################################################

# Get the wait time
wait_time=$(( $start_epoch - $current_epoch ))
echo "Wait time $(date -d @$wait_time +%H:%M:%S)"
running_time=$(( $end_epoch - $start_epoch ))
echo "Running time $(date -d @$running_time +%H:%M:%S)"
echo "Sample interval $sample_interval"
echo "Sample number $sample_number"


###################################################################
#
# Now the nohup stuff ....
#
###################################################################

TIMEOUT=0.1
#Use nohup to run the bg_wait_analysis command.
#Nohup is run in the background.

nohup ./bg_wait_analysis $wait_time $running_time $sample_interval $sample_number &

#Get last background PID ie nohup
NOHUP_PID=$!

# Echo the background PID so it can be waited on
echo $NOHUP_PID

#Kill this script after a short time
#Get current PID
MY_PID=$$
trap "exit 0" SIGINT SIGTERM
sleep $TIMEOUT && kill $MY_PID 2>/dev/null &
#If the command finishes before the timeout .... (not sure about the next bit)
wait $NOHUP_PID
NOHUP_STATUS=$?
#Print an error
[ $NOHUP_STATUS != 0 ] && echo "Errors ...."
exit $NOHUP_STATUS
