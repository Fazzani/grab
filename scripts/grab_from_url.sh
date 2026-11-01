#!/bin/bash

set -e
source "$(dirname "$0")/utils.sh"

tmpDir="${EPG_TMP_DIR:-./tmp}"
mkdir -p "$tmpDir"
downloaded=0
source_number=0

for url in "$@"; do
  ((source_number += 1))
  filename=$(basename "${url%%\?*}")
  source_id=$(hash "$url")
  downloadPath="$tmpDir/$source_id.download"
  logPath="$tmpDir/$source_id.log"
  extension="${filename##*.}"
  echoInfo "Source $source_number ($source_id)"

  if wget -S -q -O "$downloadPath" "$url" --tries=3 --timeout=30 \
    --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11" 2>"$logPath"; then
    rm -f "$logPath"
  else
    status=$?
    http_status=$(awk '/^[[:space:]]*HTTP\/[0-9.]+/ && $2 ~ /^[0-9][0-9][0-9]$/ { code=$2 } END { print code }' "$logPath")
    echoError "::warning::Source $source_number ($source_id) failed: wget exit $status${http_status:+, HTTP $http_status}" >&2
    rm -f "$downloadPath" "$logPath"
    continue
  fi

  case "$extension" in
    gz)
      command -v gunzip >/dev/null 2>&1 || { echoError "gunzip is required" >&2; exit 1; }
      if ! gunzip -c "$downloadPath" > "$tmpDir/$source_id.xml"; then
        echoError "::warning::Source $source_number ($source_id) has invalid gzip data" >&2
        rm -f "$downloadPath" "$tmpDir/$source_id.xml"
        continue
      fi
      rm -f "$downloadPath"
      ;;
    zip)
      command -v unzip >/dev/null 2>&1 || { echoError "unzip is required" >&2; exit 1; }
      archiveDir=$(mktemp -d "$tmpDir/archive.XXXXXX")
      if ! unzip -q -o "$downloadPath" -d "$archiveDir" 2>"$logPath"; then
        echoError "::warning::Source $source_number ($source_id) has invalid zip data" >&2
        rm -f "$downloadPath" "$logPath"
        rm -rf "$archiveDir"
        continue
      fi
      index=0
      while IFS= read -r -d '' file; do
        ((index += 1))
        mv "$file" "$tmpDir/$source_id-$index.xml"
      done < <(find "$archiveDir" -type f \( -iname '*.xml' -o -iname '*.xmltv' \) -print0)
      rm -f "$downloadPath" "$logPath"
      rm -rf "$archiveDir"
      if (( index == 0 )); then
        echoError "::warning::Source $source_number ($source_id) contains no XML files" >&2
        continue
      fi
      ;;
    *)
      mv "$downloadPath" "$tmpDir/$source_id.xml"
      ;;
  esac
  ((downloaded += 1))
done

if (( downloaded == 0 )); then
  echoError "No EPG sources were downloaded successfully." >&2
  exit 1
fi
echoInfo "Downloaded $downloaded of $source_number EPG sources."
