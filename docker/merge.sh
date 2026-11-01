#!/bin/bash

set -eo pipefail

command -v tv_cat >/dev/null 2>&1 && command -v tv_grep >/dev/null 2>&1 || { echo >&2 "tv_cat and tv_grep are required. Please install xmltv-util. Aborting."; exit 1; }
command -v gzip >/dev/null 2>&1 || { echo >&2 "I require gzip but it's not installed. Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "I require zip but it's not installed. Aborting."; exit 1; }

echo "Processing..................." 
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
inputs=()
for file in "$1"/*.xml; do
    [[ -f "$file" ]] || continue
    if python3 "$repo_dir/scripts/validate_xmltv.py" "$file"; then
        inputs+=("$file")
    else
        echo "::warning::Ignoring invalid XMLTV source: $file" >&2
    fi
done
(( ${#inputs[@]} > 0 )) || { echo >&2 "No valid XMLTV sources to merge."; exit 1; }
temp_merge=$(mktemp ./merge.xml.XXXXXX)
trap 'rm -f "$temp_merge"' EXIT
tv_cat --utf8 "${inputs[@]}" | tv_grep --on-after now > "$temp_merge"
[[ -s "$temp_merge" ]] || { echo >&2 "Merged XML is empty."; exit 1; }
python3 "$repo_dir/scripts/validate_xmltv.py" "$temp_merge" --require-programme
mv "$temp_merge" ./merge.xml

echo "Cleaning up.................." 
[[ -f "./merge.zip" ]] && rm "./merge.zip"
[[ -f "./merge.xml.gz" ]] && rm "./merge.xml.gz"

echo "Archiving...................."
zip -r merge.zip merge.xml
gzip -fkq merge.xml

exit 0
