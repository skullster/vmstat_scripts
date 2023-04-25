#!/bin/bash

# Pass these in as arguments
# Get the current epoch time as a reference
#start_epoch=$(date +%s)
#sample_interval=1
#sample_number=10
#running_time_secs=20
#out_file=free_mem_$start_epoch
start_epoch=$1
running_time_secs=$2
sample_interval=$3
sample_number=$4
out_file=$5

# Initialize the elapsed time
elapsed_time=0

# Initialize the wait time
wait_time=$(( $sample_interval * $sample_number ))


# Get the total available RAM
mem_total=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')

#echo $start_epoch
#echo $mem_total

while [[ $elapsed_time -lt $running_time_secs ]]
do
   vmstat -n -t $sample_interval $sample_number | \
      awk '{if (FNR > 2) {printf("%s %s %s\n", $18, $19, $4)}}' | \
      ./get_rel_epoch_pc_mem.sh $start_epoch $mem_total | \
      awk -v time_frmt=${#running_time_secs} -v test_name="free_mem" -f least_squares.awk -- >> $out_file &
   #./bg_free_mem $start_epoch $running_time_secs $sample_interval $sample_number $out_file $mem_total
   sleep ${wait_time}s

   now_epoch=$(date +%s)
   elapsed_time=$(( $now_epoch - $start_epoch ))
done
