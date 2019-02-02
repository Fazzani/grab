#!/bin/bash

#_________________________________________________________________________
# updating the channel field 'active' with false value for missed channels
# example to use:
# ./scripts/update_missed_channels.sh ./out/check_channels.1.json ./out/check_missing_programs.1.json
#_________________________________________________________________________

source $(dirname $0)/utils.sh
command -v jq >/dev/null 2>&1 || { echoError "jq required but it's not installed.  Aborting." >&2; exit 1; }

input_file=$1
missed_channels_file=$2
tmpfile="tmpppp.json"

# adding the filed active with true as default value
jq '.tv.channel[] += {"active": true}' $input_file > $tmpfile && mv $tmpfile $input_file

# make newlines the only separator
OLDIFS=$IFS
IFS=$'\n'

jq -r '.sources[].missedlist[] |[.name, .url] | @tsv' $missed_channels_file |
  while IFS=$'\t' read -r name url; do
    echoInfo "$name $url"
    #echo "$(jq -r --arg name $name --arg url $url '(.tv.channel[] | select((.id == $name) and (.url == $url)))' $input_file)"
    jq -r --arg name $name --arg url $url '(.tv.channel[] | select((.id == $name) and (.url == $url)) | .active) |= false' $input_file > $tmpfile && mv $tmpfile $input_file
  done

IFS=$OLDIFS

# updating elastic doc
curl -s -H "Content-Type:application/json" -XPUT https://elastic.synker.ovh/epg/channels/1 -d @./out/check_channels.json

echoInfo  "${NC}"
exit 0