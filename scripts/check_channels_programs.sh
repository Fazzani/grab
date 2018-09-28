#!/bin/bash
#______________________________________________________________________________
#
# Check si un une chaine dans le xmltv généré n'aurait pas des programmes
# si oui on envoie un mail 
#______________________________________________________________________________

source $(dirname $0)/.conf

function checkEpg {
        echo -e  "${NC}"
        echo -e "${GREEN}__________ Cheacking epg file =>  $1 _________"
        echo

        if [ ! -z "$1" ]; then
                fileInput="$1"
        else
                echo -e "${RED} no fileinput detected ${NC}"
                fileInput="guide.xmltv"
        fi

        grep -Ei "<channel\sid=\"(.*)\"" $fileInput | grep -oEi "\"(.*)\"" | uniq | sort> tempfile && # liste des chaines
        grep -Ei "channel=\"(.*)\"" $fileInput | grep -oEi  "channel=\"(.*)\"" | grep -oEi "\"(.*)\"" | uniq | sort> tempfile2 #liste des programmes
        # comm -3 tmpfile tmpfile2
        listChannels=$(comm -3 tempfile tempfile2) # diff des 2 files

        echo -e "${GREEN}Channels total count : "`echo $(cat tempfile | wc -l)`
        # cat tempfile | wc -l
        # echo
        echo "Channels with programmes count : "`echo $(cat tempfile2 | wc -l)`
        # cat ./tempfile2 | wc -l
        #echo
        countErrors=`echo "$listChannels"|wc -l`
        # let "countErrors=0"
        #echo $countErrors
        if [ $countErrors -ne 0 ];then
                echo -e "${RED}Channels wihout programmes count : " $(echo "$listChannels"|wc -l)
                echo
                res=$(echo -e "${listChannels}" | sed -e 's/\"/<br\/>/g')
                echo $res| column
        fi
        mes="<h4>Cheacking file $fileInput </h4><br/> $countErrors channels without programmes was detected : <br/>"
        echo "Mailing errors to administrator..."
        echo "$mes$res" | mail -a "Content-type: text/html" -s "Error webgrab" tunisienheni@gmail.com
        rm tempfile
        rm tempfile2
}

#__________________________  main __________________________

# echo "____ : $1 arg count ____ $# : ____"
if [ -z "$1" ];then
        echo "You must pass a list of epg files!!"
        exit -1
fi

outputfile="channelsEpgFile.xml"
touch $outputfile
truncate -s 0 $outputfile #vider le fichier output
for i in "$@";
do
    checkEpg $i $outputfile
done

# echo $mes | mail -s "Error webgrab" tunisienheni@outlook.com
exit 0
