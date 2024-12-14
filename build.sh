#!/bin/bash

OLDIFS=$IFS

function build {
    git clone --depth 1 https://${GIT_TOKEN}@github.com/fazzani/grab.git > /dev/null 2>&1 && \
    cd grab && \
    docker run -it --rm -v "${PWD}/${WEBGRAB_FILENAME}:/config/WebGrab++.config.xml" --hostname test --mac-address="12:34:de:b0:6b:61" -v "${PWD}:/data" synker/webgraboneshot:latest
    git add --all && (git commit -m "Webgrab ${WEBGRAB_FILENAME}" || echo "No changes to commit" && exit 0)
    git config --global http.postBuffer 524288000

    local counter=0
    until [ $counter -gt 5 ]; do
        { { git pull &> /dev/null && git push -f; } && break; } || ((counter++))
        echo Transfer disrupted, retrying in 10 seconds...
        sleep 10
    done
}

function merge {
    sudo apt-get install -yqq --no-install-recommends \
       xmltv-util \
       dos2unix \
       zip
    
    dos2unix docker/merge.sh && \
    chmod +x docker/merge.sh && \
    docker/merge.sh ./tmp
}

function stats {
    local month_ago_date=$(date --date="-${1:-7} day" +%F)
    local data_file_path="/tmp/tmp_epg.csv"
    local merge_file_path="/tmp/epg_merge.csv"

    echo "Filtering git commits from $month_ago_date"
    [[ -f $merge_file_path ]] && rm $merge_file_path

    for commit in $(git log --after="$month_ago_date" --format=%h -- out/epg.csv)
        do
        git show $commit:out/epg.csv > $data_file_path
        python3 scripts/stats_epg.py -p $data_file_path
        [[ -f $data_file_path ]] && rm $data_file_path
    done
    python3 scripts/stats_epg.py -s
}

BUILD=false
MERGE=false
for arg in "$@"
do
    case "$arg" in
    "--build")
        BUILD=true
        ;;
    "--download")
        shift
        chmod +x ./scripts/grab_from_url.sh && ./scripts/grab_from_url.sh $@
        ;;
    "--merge")
        MERGE=true
        ;;
    "--check")
        shift
        pip install pandas --break-system-packages
        python3 ./scripts/check.py .
        ;;
    "--stats")
        shift
        pip install pandas --break-system-packages
        python3 ./scripts/stats_epg.py -s -f out/epg.csv
        exit 0
        ;;
    esac
    shift
done

[[ $BUILD = true ]] && build
[[ $MERGE = true ]] && merge

exit 0