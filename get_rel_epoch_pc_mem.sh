#!/bin/bash
# $1 - start time
# $2 - total memory

while IFS=" " read -r xdate xtime yvalue; do
   epoch_time=`date -d "$xdate $xtime" +"%s"`
   rel_epoch=`expr $epoch_time - $1`
   pc_mem=$(echo "scale=6; ($yvalue * 100)/ $2" | bc -l)
   printf "%d %s\n" $rel_epoch $pc_mem
done
