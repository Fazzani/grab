#!/bin/bash

source $(dirname $0)/utils.sh

tmpDir="$(dirname $0)/tmp"
echoInfo "$(dirname $tmpDir)"
mkdir -p $tmpDir

for url in "$@"
do
  filename=$(basename $url)
  localzipName=`echo $filename | awk -F '?' '{print $1}'`
  fileDestTmp=$(hash $url)
  fileDest="${filename%.*}"
  extension="${localzipName##*.}"

  echoInfo "___localzipName: ${localzipName} _________"
  echoInfo "_____extension : ${extension} _________"
  echoInfo "_____ fileDest : ${fileDest} _________"
  echoInfo "___fileDestTmp : ${fileDestTmp} _________"
  echoInfo "___________tmp : ${tmpDir} _________"

  wget -q -O $tmpDir/$localzipName $url \
  --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11" \
  --no-check-certificate
  
  if [ $extension = "zip" ]; then
    command -v unzip >/dev/null 2>&1 || { echoError "unzip required but its'nt installed. Aborting." >&2; exit 1; }
    echoInfo "Unzip file..."
    unzip -q -o $tmpDir/$localzipName -d $tmpDir/
    fileDest=$localzipName
  elif [ $extension = "gz" ]; then
    command -v gunzip >/dev/null 2>&1 || { echoError "gunzip required but its'nt installed. Aborting." >&2; exit 1; }
    echoInfo "Extrat gz file..."
    gunzip -f $tmpDir/$localzipName > "$tmpDir/$fileDestTmp.xml"
    fileDest="$fileDestTmp"
  else
    sudo mv $tmpDir/$localzipName $tmpDir/$fileDestTmp.xml
    fileDest="$fileDestTmp"
  fi

  # sudo mv $tmpDir/$fileDest.xml $fileDest.xmltv &&
  echoInfo "${url} grab finished successfully"
  echo
  # if [ -z $localzipName ]; then
  #   echoInfo "Deleting $tmpDir/$localzipName ..."
  #   sudo rm $tmpDir/$localzipName
  # fi
done

exit 0
