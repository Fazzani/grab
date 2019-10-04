#!/bin/bash

set -e

command -v tv_merge >/dev/null 2>&1 || { echo >&2 "I require tv_merge but it's not installed. Please install xmltv-util package. Aborting."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo >&2 "I require tar but it's not installed.  Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed.  Aborting."; exit 1; }

output="merge.xmltv"
i=0
verbose=${VERBOSE:-false}

[[ $verbose = true ]] && echo "pattern to match $1"

for filename in "$@";do

  [[ $verbose = true ]] && echo "filename => $filename" 

  [[ $(grep -c "<programme" "$filename") -eq 0 ]] && continue

  if [[ "$filename" = "merge.xmltv" ]]; then
    continue
  fi

  if [[ $i -eq 0 ]]; then
    second=$filename
    i=$((i+1))
    continue
  fi

  if [[ $i -gt 1 ]]; then
    second=$output
  fi

  [[ $verbose = true ]] && echo "filename => $filename will be merged with $second" 

  echo -e "merge ${filename} $second"
  /usr/bin/tv_merge -i "$filename" -m $second -o $output
  i=$((i+1))

done;

[[ ! -f ./merge.xmltv ]] && echo "merge.xmltv file not generated!" && exit 0

mv ./merge.xmltv ./merge.xml && tar zcvf merge.tar.gz merge.xml && zip -r merge.zip merge.xml && rm merge.xml

exit 0