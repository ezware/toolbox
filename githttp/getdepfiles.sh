#!/bin/bash
. func.sh

app=$1
if "$app" == "" ]; then
    app=strace
fi

copyDep "$(which $app)"
