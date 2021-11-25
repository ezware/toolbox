#!/bin/bash

#$1 path
function genDoc {
    pushd "$1" >/dev/null

    local doc=
    local files=$(find . ! -type l | grep \.py$ | grep -v __init__ | grep -v setup.py | grep -v tests | sort)
    
    for f in $files
    do
        doc=$(pydocgen.awk < "$f")
        [ ! -z "$doc" ] && echo -e "# $f\n---\n${doc}\n"
    done

    popd >/dev/null
}

genDoc $1
