#!/bin/bash

OLDIFS=$IFS

function build {
    docker run -it --rm -v "${PWD}/${WEBGRAB_FILENAME}:/config/WebGrab++.config.xml" --hostname test --mac-address="12:34:de:b0:6b:61" -v "${PWD}:/data" synker/webgraboneshot:latest
    git remote add origin2 https://${GITHUB_API_TOKEN}@github.com/fazzani/grab.git > /dev/null 2>&1
    git add --all && (git commit -m "Webgrab ${WEBGRAB_FILENAME}" || echo "No changes to commit" && exit 0)
    git config --global http.postBuffer 524288000

    counter=0
    until [ $counter -gt 5 ]; do
        git pull origin2 master &> /dev/null && git push origin2 HEAD:master -f && break || ((counter++))
        echo Tansfer disrupted, retrying in 10 seconds...
        sleep 10
    done
}

function merge {
    git clone --depth 1 https://${GITHUB_API_TOKEN}@github.com/fazzani/grab.git > /dev/null 2>&1 \
    && cd grab \
    && chmod +x ../docker/merge.sh

    docker run -it -v "${PWD}:/work" -e GITHUB_API_TOKEN=${GITHUB_API_TOKEN} synker/xmltv_merge:latest /bin/bash -c "dos2unix docker/merge.sh && chmod +x docker/merge.sh && docker/merge.sh *.xmltv"

    [[ ! -z $(git status -uno --porcelain) ]] \
    && git status \
    && git add merge.tar.gz merge.zip \
    && git commit -m "compression and merging xmltv files. Triggred by $TRAVIS_EVENT_TYPE" && \
    git config --global http.postBuffer 524288000

    counter=0
    until [ $counter -gt 5 ]; do
        git pull -X ours > /dev/null 2>&1 && git push -f && break || ((counter++))
        echo Tansfer disrupted, retrying in 10 seconds...
        sleep 10
    done
}

BUILD=false
MERGE=false

for arg in "$@"
do
    case "$arg" in
    "--build")
        BUILD=true
        ;;
    "--merge")
        MERGE=true
        ;;
    esac
    shift
done

[[ $BUILD = true ]] && build
[[ $MERGE = true ]] && merge

exit 0