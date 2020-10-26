#!/bin/bash

function copyDep {
    #copy libs
    ldd ../githttp | grep '=>' | awk  '{print $3}' | xargs -i\\ cp --parents \\ .

    #copy ld
    ldd ../githttp | grep ld-linux | awk '{print $1}' | xargs -i\\ cp --parents \\ .

}

function build {
    if [ ! -f ../githttp ]; then
        pushd ../
            go build
        popd
    fi

    #copy githttp
    mkdir -p bin && cp ../githttp bin/
    cp -rf ../scripts .

    echo "Copying dependencies"
    copyDep

    echo "Building docker image"
    docker build -t githttp:latest .
}

#$0
#TODO pushd to script path
build
