#!/bin/bash

SCRIPT_PATH=$(realpath "$0")
SCRIPT_PATH=${SCRIPT_PATH%/*}

#include functoins
. ${SCRIPT_PATH}/func.sh

WORKDIR=./
if [ "$1" != "" ]; then
    WORKDIR=$1
fi

pushd "$WORKDIR"
    replaceMirror 
    replaceGoogle
    replaceDocker
    replacePypi
    replaceSonicStorage
    replaceDepotTools
    replaceGithub
    modifyPyVer
    removeOldLibprotobuf
    addShmOption
    addNatsort
    addDockerAttachment
    modifyAptSrc
    removeNoCacheIndicator
    replaceGPGURL
    replaceFileServer
    addGoProxy
    tempFix
    addXXXNOSVer
    addRepack
popd

echo "Adapting local mirror"
"${SCRIPT_PATH}/tolocalmirror.sh" "$WORKDIR"
"${SCRIPT_PATH}/localize_repo.sh" "$WORKDIR"
