#!/bin/bash

#$1 url file
#$2 repo dir
urlfile=./git.url
if [ "$1" != "" ]; then
    urlfile="$1"
fi

repodir=./
if [ "$2" != "" ]; then
    repodir="$2"
fi

function mirrorit {
    urls=$(cat "$urlfile")
    for url in $urls
    do
        repohome=$(echo "$url" | cut -d / -f4)
        if [ "$repohome" == "" ]; then
            echo "skipping $url"
            continue
        fi
        mkdir -p "$repohome"
        if [ ! -d "$repohome" ]; then
            echo "skipping $url"
            continue
        fi
        pushd "$repohome"
            reponame=$(echo "$url" | cut -d / -f5)
            reponogit=${reponame%.git}
            repowithgit=$reponame
            if [ "$repowithgit" == "$reponogit" ]; then
                repowithgit="${reponogit}.git"
            fi
            echo "reponame: $reponame, reponogit: $reponogit, repowithgit: $repowithgit"
            if [ ! -d "$repowithgit" ]; then
                echo "Creating mirror of $url to $repowithgit"
                mygit clone --mirror "$url"
            else
                echo "$repowithgit exists, skipping"
            fi
            if [ ! -e "$reponogit" ]; then
                echo "Creating link $reponogit to $repowithgit"
                ln -s "$repowithgit" "$reponogit"
            fi
        popd
    done
}

pushd "$repodir"
    mirrorit
popd
