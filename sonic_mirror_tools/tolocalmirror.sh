#!/bin/bash

WORKDIR=./

if [ "$1" != "" ]; then
    WORKDIR=$1
fi

LOCAL_REPO_MIRROR=10.153.3.130

if [ "$HTTP_SERVER_IP" == "" ]; then
    HTTP_SERVER_IP=172.17.0.1
fi

function replaceMirror {
    tobeReplace="mirrors.tuna.tsinghua.edu.cn"
    replaceTo="${LOCAL_REPO_MIRROR}"
    echo "Searching files for deb mirror replace"
    files=$(grep -Er 'mirrors.tuna.tsinghua.edu.cn' | grep -E 'deb|pypi|docker' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        for rr in $tobeReplace
        do
            sed -i "s/$rr/$replaceTo/g" $f
        done
    done
}

function replaceGolangMirror {
    echo "Searching files for golang mirror replace"
    files=$(grep -Er 'studygolang.com' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s/https:\/\/studygolang.com/http:\/\/${HTTP_SERVER_IP}/g" "$f"
    done
}

function replaceSonicMirror {
    echo "Searching files for sonicstorage replace"
    files=$(grep -Er 'sonicstorage.blob.core.windows.net' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s/sonicstorage.blob.core.windows.net/${HTTP_SERVER_IP}/g" "$f"
    done

    #patch: change back to debian mirror
    f="src/sonic-linux-kernel/Makefile"
    sed -i "s|${HTTP_SERVER_IP}/debian|${LOCAL_REPO_MIRROR}/debian|g" "$f"
}

function changeHttps {
    echo "Searching files for https replace"
    files=$(grep -Er "https://${LOCAL_REPO_MIRROR}" | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s/https:\/\/${LOCAL_REPO_MIRROR}/http:\/\/${LOCAL_REPO_MIRROR}/g" "$f"
    done
    
}

function replaceDepot {
#sed -i 's/chromium.googlesource.com\/chromium\/tools/gitee.com\/oceanho/g' "$f"
    sed -i 's/^.*gitee.com\/oceanho.*$/RUN curl -O -L http:\/\/172.17.0.1\/chromium\/tools\/depot_tools.tar.gz \&\& tar -C \/usr\/share\/ -xf depot_tools.tar.gz/' "$f"
}

pushd "$WORKDIR"
    replaceMirror 
    replaceGolangMirror
    replaceSonicMirror
    replaceDepot
    changeHttps
popd

