#!/bin/bash

set -e

command -v tv_merge >/dev/null 2>&1 || { echo >&2 "I require tv_merge but it's not installed. Please install xmltv-util package. Aborting."; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo >&2 "I require gzip but it's not installed. Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed. Aborting."; exit 1; }

output="merge.xmltv"
i=0
verbose=${VERBOSE:-false}

[[ $verbose = true ]] && echo "pattern to match $1"

for filename in "$1"/*.xml; do

  [[ $verbose = true ]] && echo "filename => $filename" 

  [[ $(grep -c "<programme" "$filename") -eq 0 ]] && echo "no programs" && continue

  if [[ "$filename" = "merge.xml" ]]; then
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

[[ ! -f $output ]] && echo "merge.xmltv file not generated!" && exit 0

/usr/bin/tv_grep --on-after now $output > ./merge.xml

[[ -f "./merge.zip" ]] && rm "./merge.zip"
[[ -f "./merge.xml.gz" ]] && rm "./merge.xml.gz"
zip -r merge.zip merge.xml
gzip -fkq merge.xml

exit 0