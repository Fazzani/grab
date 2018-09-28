#!/bin/bash

source $(dirname $0)/utils.sh

tmpDir="$(dirname $0)/tmp"
echoInfo "$(dirname $tmpDir)"

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

  sudo wget -q -O $tmpDir/$localzipName $url --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11" --no-check-certificate
  if [ $extension = "zip" ]; then
    echoInfo "Unzip file..."
    unzip -q -o $tmpDir/$localzipName -d $tmpDir/
    fileDest=$localzipName
  else
    sudo mv $tmpDir/$localzipName $tmpDir/$fileDestTmp.xml
    fileDest="$fileDestTmp"
  fi

  sudo mv $tmpDir/$fileDest.xml /home/pi/toshiba/xmltv/$fileDest.xmltv &&
  cat /home/pi/toshiba/xmltv/$fileDest.xmltv | socat - UNIX-CONNECT:/home/hts/.hts/tvheadend/epggrab/xmltv.sock &&
  push_msg "${url} grab finished successfully"
  if [ -z $localzipName ]; then
    sudo rm $tmpDir/$localzipName
  fi
done

exit 0
# sudo wget -O /tmp/complet.zip http://kevinpato.free.fr/xmltv/download/complet.zip  --header="User-Agent: Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11" --header="Referer: http://xmodulo.com/" --header="Accept-Encoding: compress, gzip" --no-check-certificate
 #sudo wget --header="Cache-Control: no-cache" --no-check-certificate /tmp/tvguide.zip http://kevinpato.free.fr/xmltv/download/complet.zip --no-cache
