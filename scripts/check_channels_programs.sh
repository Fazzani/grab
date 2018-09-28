#!/bin/bash
#______________________________________________________________________________
#
# Check si un une chaine dans le xmltv généré n'aurait pas des programmes collectés
# si oui, on push une notification 
#______________________________________________________________________________

source $(dirname $0)/utils

function check_missing_epg {
  echoInfo "${NC}"
  echoInfo -e "$__________ Cheacking epg file =>  $1 _________"
  echo

  if [ ! -z "$1" ];then
    fileInput="$1"
  else
    echoError "no fileinput detected ${NC}"
    fileInput="guide.xmltv"
  fi

  grep -Ei "<channel\sid=\"(.*)\"" $fileInput | grep -oEi "\"(.*)\"" | uniq | sort> tempfile && # liste des chaines
  grep -Ei "channel=\"(.*)\"" $fileInput | grep -oEi  "channel=\"(.*)\"" | grep -oEi "\"(.*)\"" | uniq | sort> tempfile2 #liste des programmes
  # comm -3 tmpfile tmpfile2
  listChannels=$(comm -3 tempfile tempfile2) # diff des 2 files
  echoInfo "Channels total count : "`echo $(cat tempfile | wc -l)`
  echoInfo "Channels with programmes count : "`echo $(cat tempfile2 | wc -l)`
  countErrors=`echo "$listChannels" | wc -l`
  
  if [ $countErrors -ne 0 ];then
    echo -e "${RED}Channels wihout programmes count : " $(echo "$listChannels"|wc -l)
    echo
    res=$(echo -e "${listChannels}" | sed -e 's/\"/<br\/>/g')
    echo $res | column
  fi

  mes="<h4>Cheacking file $fileInput </h4><br/> $countErrors channels without programmes was detected : <br/>"
  echoInfo "Pushing notification"
  push_message "Error webgrab" "$mes$res"

  rm tempfile
  rm tempfile2
}

#__________________________  main __________________________

# echo "____ : $1 arg count ____ $# : ____"
if [ -z "$1" ];then
  echo "You must pass a list of epg files!!"
  exit -1
fi

outputfile="check_missing_programs.xml"
touch $outputfile
truncate -s 0 $outputfile #vider le fichier output

for i in "$@"; do
  check_missing_epg $i $outputfile
done

exit 0