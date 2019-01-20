#!/bin/bash

APP_TOKEN="a1zc9d81aw14ezws414n7uvsnz2xio"
USER_TOKEN="uxepp2gjx5ch4eveufj8fo8jmcm6we"

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

#----------------------------------------
# Auto connect SSH take passphrase as arg
#----------------------------------------
function ssh-auto-connect {
  command -v expect >/dev/null 2>&1 || { echo "expect command required but it's not installed.  Aborting." >&2; exit 1; }

if [ $# -ne 1 ]; then
  echo "Usage: autoConnectSSH password"
  exit 1
fi
eval $(ssh-agent)

expect << EOF
  spawn ssh-add
  expect "Enter passphrase"
  send "$1\r"
  expect eof
EOF
}

function push_msg {
  message="${0} grab finished successfully"
  sudo wget https://api.pushover.net/1/messages.json --post-data="token=${APP_TOKEN}&user=${USER_TOKEN}&title=WebGrabber+message&message=$message."  -qO-  > /dev/null 2>>4 &
}

function hash {
  echo `/bin/echo $0 | /usr/bin/md5sum | cut -f1 -d" "`
}

# args <message> [title]
function push_message {
  if [ $# -eq 0 ]; then
	echo "Usage: ./pushover <message> [title]"
	exit
  fi

  MESSAGE=$1
  TITLE=$2

  if [ $# -lt 2 ]; then
	TITLE="`whoami`@${HOSTNAME}"
  fi

  wget https://api.pushover.net/1/messages.json --post-data="token=$APP_TOKEN&user=$USER_TOKEN&message=$MESSAGE&title=$TITLE" -qO- > /dev/null 2>&1 &
}

