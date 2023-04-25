#!/bin/bash
# Get list of available disks/disk mapping from vmstat
# Compare with lsblk to get associated file systems.
# Ignore loops, roms and partitions - the latter do not feature in vmstat -d
declare -A disk_arr
while read name fs_or_type; do
    disk_arr[$name]=$fs_or_type
done < <(vmstat -d | awk '{print $1}' | grep -f - <(lsblk -all) | egrep -v "loop|part|rom" | sed 's/(//g' | sed 's/)//g' | awk '/disk/ {printf("%s %s\n", $1, $6)} /lvm/ {printf("%s %s\n", $2,$8)}')

for key in "${!disk_arr[@]}"; do printf "%s\t%s\n" "$key" "${disk_arr[$key]}"; done
