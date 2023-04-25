#!/bin/bash

# An array to keep tabs on the background PIDs
declare -A pid_array
declare -A out_file_array

# Pass these in as arguments
#running_time_secs=20
#sample_interval=1
#sample_number=10
running_time_secs=$1
sample_interval=$2
sample_number=$3

# Initialize the elapsed time
elapsed_time=0

# Get the current epoch time as a reference
start_epoch=$(date +%s)

#echo $start_epoch

# Initialize the PID array
pid_array["free_mem"]=0
pid_array["swap"]=0

# Create output files - using current epoch time so not testing
# free mem test
out_file_free_mem=free_mem_${start_epoch}
touch $out_file_free_mem
out_file_array["free_mem"]=$out_file_free_mem
# swap test
out_file_swap=swap_${start_epoch}
touch $out_file_swap
out_file_array["swap"]=$out_file_swap

# Kick-off free mem analysis
#pid_array["free_mem"]=$(./bg_free_mem_analysis $start_epoch $running_time_secs $sample_interval $sample_number $out_file_free_mem)
./bg_free_mem_analysis $start_epoch $running_time_secs $sample_interval $sample_number $out_file_free_mem
./bg_swap_analysis $start_epoch $running_time_secs $sample_interval $sample_number $out_file_swap

echo "${pid_array[free_mem]}"
