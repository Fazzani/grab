#!/bin/bash
#______________________________________________________________________________
#
# Check si un une chaine dans le xmltv généré n'aurait pas des programmes
# si oui on envoie un mail
# on met à jour le fichier utilisé par l'application web qui contient la liste de références des chaines ayant des EPG
#______________________________________________________________________________

source $(dirname $0)/utils.sh

# Check if command installed
command -v xmllint >/dev/null 2>&1 || { echoError "libxml2-utils required but it's not installed.  Aborting." >&2; exit 1; }
command -v xml2json >/dev/null 2>&1 || { echoError "The package npm xml2json-cli required but it's not installed.  Aborting." >&2; exit 1; }
command -v xmlstarlet >/dev/null 2>&1 || { echoError "The package xmlstarlet required but it's not installed.  Aborting." >&2; exit 1; }

# arg0: input file
# arg1: output file
# arg2: output file json
# arg3: output file missing programs
function checkChannels {
    echoInfo  "${NC}"

    if [ ! -z "$1" ]; then
	  fileInput="$1"
    else
	  echoError "no fileinput detected"
	  fileInput="guide.xmltv"
    fi

    echo "Extract all channels from Xmltv file: $fileInput"
    tmp="tmp"
    echo "<tv>" > $tmp
    xmllint --encode utf8 --xpath '//channel' $fileInput >> $tmp
    echo "</tv>" >> $tmp
    country=${fileInput#*_}
    country=${country%.xmltv}
    xmlstarlet ed -i "//channel" -t attr -n "country" -v "$country" "$tmp" > "$tmp.xml"
    xmllint --encode utf8 --xpath '//channel' "$tmp.xml" >> "$2"
    rm tmp*

    # check missing programs

    grep -Ei "<channel\sid=\"(.*)\"" $fileInput | grep -oEi "\"(.*)\"" | uniq | sort > tempfile # liste des chaines
    grep -Ei "channel=\"(.*)\"" $fileInput | grep -oEi  "channel=\"(.*)\"" | grep -oEi "\"(.*)\"" | uniq | sort > tempfile2 #liste des programmes

    listChannels=$(comm -3 tempfile tempfile2) # diff des 2 files
    echo $listChannels
    total=`echo $(cat tempfile | wc -l)`
    not_missed=`echo $(cat tempfile2 | wc -l)`
    countErrors=`echo $((comm -3 tempfile tempfile2) | wc -l )`

    echoInfo "Channels total count : $total"
    echoInfo "Channels with programmes count : $not_missed"

    if [ $countErrors -ne 0 ];then
      echoError "Channels wihout programmes count : $countErrors"
      echo

      echo "{\"filename\":\"$fileInput\",\"total\":$total,\"missed\":$countErrors,\"missedlist\":" >> $4
      res=$(echo "[${listChannels}]}," | sed -e 's/\"$/",/g')
      echo $res | column
      echo "${res}" >> $4
     # mes="<h4>Cheacking file $fileInput </h4><br/> $countErrors channels without programmes was detected : <br/>"
     # echoInfo "Pushing notification"
     # push_message "Error webgrab" "$mes$res"
    fi

    rm tempfile
    rm tempfile2

    echoInfo  "${NC}"
}

function push_to_git {
  git remote add origin2 https://${GITHUB_API_TOKEN}@github.com/fazzani/grab.git > /dev/null 2>&1
  git add $@ && \
  git commit -m "check channels" && \
  git pull origin2 HEAD:master && \
  git push origin2 HEAD:master
}

#__________________________  main __________________________
# echo "____ : $1 arg count ____ $# : ____"
if [ -z "$1" ];then
	echoInfo "You must pass a list of epg files!!"
	exit -1
fi
now=$(date +"%d/%m/%Y")
echo $now

outputfile="out/check_channels.xml"
outputfile_json="out/check_channels.json"
outputfile_missing_prog="out/check_missing_programs.json"

#vider les fichiers output
echo "" > $outputfile > $outputfile_json
echo "{\"report\":{\"date\":\"$now\",\"sources\":[" > $outputfile_missing_prog
#convert encoding to utf-8
echo -ne '\xEF\xBB\xBF' > $outputfile
#file -i $outputfile
echo '<?xml version="1.0" encoding="UTF-8"?><tv generator-info-name="WebGrab+Plus/w MDB &amp; REX Postprocess -- version  V2.0 -- Jan van Straaten" generator-info-url="http://www.webgrabplus.com">' >> $outputfile

for i in "$@";
do
    checkChannels $i $outputfile $outputfile_json $outputfile_missing_prog &
	wait
done

echo '</tv>' >> $outputfile

# formating channels without programs file
content_missing=$(cat $outputfile_missing_prog)
echo ${content_missing%,}"]}}" > $outputfile_missing_prog
# Generate json version

xml2json $outputfile $outputfile_json

# Generate readme.md

echo -e "# Daily EPG" > readme.md
echo -e "[![Build Status](https://travis-ci.org/Fazzani/grab.svg?branch=master)](https://travis-ci.org/Fazzani/grab)" >> readme.md
echo -e "## channels list" >> readme.md
echo -e "[All channels link](https://github.com/Fazzani/grab/blob/master/merge.tar.gz?raw=true)\n\r" >> readme.md
echo -e "\r\n" >> readme.md
cat $outputfile_json | jq -r '.tv.channel[] | [ .id, .url, .icon.src ] | @csv' | tr -d \" | \
awk -v FS="," 'BEGIN{printf "|Icon|Channel|Site|\n";printf "|:----|:---:|:---:|\n"}{printf "|![icon](%s)|%s|%s|\n",$3,$1,$2}' >>  readme.md

#curl \
#-H "Accept: application/json" \
#-H "Content-Type:application/json" \
#-X POST --data @<( cat $outputfile_json ) https://api.myjson.com/bins 

# Push to Git
push_to_git $outputfile $outputfile_json $outputfile_missing_prog readme.md

echo -e  "The End.${NC}"
exit 0

