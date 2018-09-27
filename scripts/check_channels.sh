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

# arg0: input file
# arg1: output fie
function checkForNewChannels {
	echo -e  "${NC}"
	echoInfo "__________ Cheacking epg file for new channels =>  $1 to $2"
	echo

	if [ ! -z "$1" ]; then
		fileInput="$1"
	else
		echoError "no fileinput detected"
		fileInput="guide.xmltv"
	fi

	echo 'Extract all channels from Xmltv file'
        tmp="tmp"
        echo "<tv>" > $tmp
        xmllint --encode utf8 --xpath '//channel' $1 >> $tmp
        echo "</tv>" >> $tmp
        country=${1#*_}
        country=${country%.xmltv}
        xmlstarlet ed -i "//channel" -t attr -n "country" -v "$country" "$tmp" > "$tmp.xml"

        xmllint --encode utf8 --xpath '//channel' "$tmp.xml" >> "$2"
        rm tmp*
	echo -e  "${NC}"
}

#__________________________  main __________________________
# echo "____ : $1 arg count ____ $# : ____"
if [ -z "$1" ];then
	echoInfo "You must pass a list of epg files!!"
	exit -1
fi

outputfile="check_channels.xml"
outputfile_json="check_channels.json"
echo "" > $outputfile #vider le fichier output
#convert encoding to utf-8
echo -ne '\xEF\xBB\xBF' > $outputfile
#file -i $outputfile
echo '<?xml version="1.0" encoding="UTF-8"?><tv generator-info-name="WebGrab+Plus/w MDB &amp; REX Postprocess -- version  V2.0 -- Jan van Straaten" generator-info-url="http://www.webgrabplus.com">' >> $outputfile
 
for i in "$@";
do
    checkForNewChannels $i $outputfile &
	wait
done
echo '</tv>' >> $outputfile

# Generate json version

xml2json $outputfile $outputfile_json

cat $outputfile_json | jq -r '.tv.channel[] | [ .id, .url, .icon.src ] | @csv' | tr -d \" | \
awk -v FS="," 'BEGIN{printf "|ID\t|Url\t|Icon|\n";printf "|:----|:---:|:---:|\n"}{printf "|%s|%s|%s|\n",$1,$2,$3}' >  channels.md

#curl \
#-H "Accept: application/json" \
#-H "Content-Type:application/json" \
#-X POST --data @<( cat $outputfile_json ) https://api.myjson.com/bins 

# Push to Git

git remote add origin2 https://${GITHUB_API_TOKEN}@github.com/fazzani/grab.git > /dev/null 2>&1
git add $outputfile $outputfile_json channels.md && git commit -m "check channels" && git push origin2 HEAD:master

echo -e  "The End.${NC}"
exit 0
