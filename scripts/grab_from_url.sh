#!/bin/bash

set -e

source "$(dirname "$0")/utils.sh"

# tmpDir="$(dirname $0)/tmp"
# echoInfo "$(dirname $tmpDir)"
tmpDir="./tmp"
mkdir -p "$tmpDir"

for url in "$@"
do
  filename=$(basename "${url%%\?*}")
  localzipName="$filename"
  fileDestTmp=$(hash "$url")
  downloadPath="$tmpDir/$fileDestTmp.download"
  fileDest="${filename%.*}"
  extension="${localzipName##*.}"

  echoInfo "___localzipName: ${localzipName} _________"
  echoInfo "_____extension : ${extension} _________"
  echoInfo "_____ fileDest : ${fileDest} _________"
  echoInfo "___fileDestTmp : ${fileDestTmp} _________"
  echoInfo "___________tmp : ${tmpDir} _________"

  wget -q -O "$downloadPath" "$url" \
  --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11"
  
  if [ "$extension" = "zip" ]; then
    command -v unzip >/dev/null 2>&1 || { echoError "unzip required but its'nt installed. Aborting." >&2; exit 1; }
    echoInfo "Unzip file..."
    unzip -q -o "$downloadPath" -d "$tmpDir/"
    rm "$downloadPath"
    fileDest=$localzipName
  elif [ "$extension" = "gz" ]; then
    command -v gunzip >/dev/null 2>&1 || { echoError "gunzip required but its'nt installed. Aborting." >&2; exit 1; }
    echoInfo "Extrat gz file..."
    if ! gunzip -c "$downloadPath" > "$tmpDir/$fileDestTmp.xml"; then
      rm -f "$tmpDir/$fileDestTmp.xml"
      exit 1
    fi
    rm "$downloadPath"
    fileDest="$fileDestTmp"
  else
    mv "$downloadPath" "$tmpDir/$fileDestTmp.xml"
    fileDest="$fileDestTmp"
  fi

  # sudo mv $tmpDir/$fileDest.xml $fileDest.xmltv &&
  echoInfo "${fileDest} grab finished successfully"
  echo
  # if [ -z $localzipName ]; then
  #   echoInfo "Deleting $tmpDir/$localzipName ..."
  #   sudo rm $tmpDir/$localzipName
  # fi
done

exit 0
