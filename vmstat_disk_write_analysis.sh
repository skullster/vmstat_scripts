#!/bin/bash

# Pass these in as arguments
# Get the current epoch time as a reference
start_epoch=$1
running_time_secs=$2
sample_interval=$3
sample_number=$4
out_file=$5
part_name=$6

# Initialize the elapsed time
elapsed_time=0

# Initialize the wait time
wait_time=$(( $sample_interval * $sample_number ))

# Set up current epoch time
now_epoch=$(date +%s)

while [[ $elapsed_time -lt $running_time_secs ]]
do
   vmstat -d $sample_interval $sample_number | grep $part_name | \
      awk '{print $8}' | \
      ./add_rel_epoch.sh $start_epoch $now_epoch $sample_interval | \
      awk -v time_frmt=${#running_time_secs} -v test_name="${part_name}_write" -f least_squares.awk -- >> $out_file &

   sleep ${wait_time}s

   now_epoch=$(date +%s)
   elapsed_time=$(( $now_epoch - $start_epoch ))
done
