#!/bin/bash

# Pass these in as arguments
# Get the current epoch time as a reference
start_epoch=$1
running_time_secs=$2
sample_interval=$3
sample_number=$4
out_file=$5

# Initialize the elapsed time
elapsed_time=0

# Initialize the wait time
wait_time=$(( $sample_interval * $sample_number ))

# Get the total available swap
swap_total=$(cat /proc/swaps | awk 'BEGIN{SWAP_TOTAL=0} {if (NR > 1) {SWAP_TOTAL+=$3}} END{print SWAP_TOTAL}')

while [[ $elapsed_time -lt $running_time_secs ]]
do
   vmstat -n -t $sample_interval $sample_number | \
      awk '{if (FNR > 2) {printf("%s %s %s\n", $18, $19, $3)}}' | \
      ./get_rel_epoch_pc_mem.sh $start_epoch $swap_total | \
      awk -v time_frmt=${#running_time_secs} -v test_name="swap" -f least_squares.awk -- >> $out_file &

   sleep ${wait_time}s

   now_epoch=$(date +%s)
   elapsed_time=$(( $now_epoch - $start_epoch ))
done
