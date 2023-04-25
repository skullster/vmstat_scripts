#!/bin/bash
# $1 - reference epoch
# $2 - command start epoch
# $3 - sample interval

delta_epoch=$(( $2 - $1 ))
increment_epoch=0
while IFS=" " read -r yvalue; do
   line_epoch=$(( $delta_epoch + $increment_epoch ))
   increment_epoch=$(( $increment_epoch + $3 ))
   printf "%d %s\n" $line_epoch $yvalue
done