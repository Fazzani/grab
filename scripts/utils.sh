#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

function echoInfo {
  echo -e "${GREEN}$1${NC}"
}

function echoError {
  echo -e "${RED}$1${NC}"
}

function hash {
  printf '%s\n' "$1" | md5sum | cut -f1 -d" "
}

function split_epg_urls {
  mapfile -t epg_urls < <(printf '%s\n' "$1" | tr ';[:space:]' '\n' | sed '/^$/d')
}
