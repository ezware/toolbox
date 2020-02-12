#!/bin/bash

function downit {
  local url=$1
  local i=1

  echo "Downloading $url"
  while ((1))
  do
    echo -e -n "\r$i times"
    ret=$(curl -C - -O -fsSL --connect-timeout 3 --expect100-timeout 3 $url)
    if ((ret==0)); then
        break
    fi
    ((i++))
  done
  echo "Done."
}

downit $1
