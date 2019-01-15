#!/bin/bash

#_________________________________________________________________________
# updating the channel field 'active' with false value for missed channels
# example to use:
# update_missed_channels.sh check_channels.1.json check_missing_programs.1.json
#_________________________________________________________________________

input_file=$1
missed_channels_file=$2
tmpfile="tmpppp.json"

IFS=$'\n'     # make newlines the only separator

for missed in $(jq -r '.sources[].missedlist[]' $missed_channels_file); do
  echo $missed
  jq -r --arg v $missed '(.tv.channel[] | select(.id == $v) | .active) |= false' $input_file > $tmpfile && mv $tmpfile $input_file
done

exit 0