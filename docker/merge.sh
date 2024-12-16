#!/bin/bash

set -e

command -v tv_merge >/dev/null 2>&1 || { echo >&2 "I require tv_merge but it's not installed. Please install xmltv-util package. Aborting."; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo >&2 "I require gzip but it's not installed. Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed. Aborting."; exit 1; }

echo "Processing..................." 
/usr/bin/tv_cat --utf8 "$1"/*.xml | /usr/bin/tv_grep --on-after now > ./merge.xml

echo "Cleaning up.................." 
[[ -f "./merge.zip" ]] && rm "./merge.zip"
[[ -f "./merge.xml.gz" ]] && rm "./merge.xml.gz"

echo "Archiving...................."
zip -r merge.zip merge.xml
gzip -fkq merge.xml

exit 0