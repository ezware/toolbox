#!/bin/bash

function copyDep {
    dest=$1
    #copy libs
    ldd "$dest" | grep '=>' | awk  '{print $3}' | xargs -i\\ cp --parents \\ .

    #copy ld
    ldd "$dest" | grep ld-linux | awk '{print $1}' | xargs -i\\ cp --parents \\ .
}

function build {
    if [ ! -f ./githttp ]; then
        go build
    fi

    #copy githttp
    pushd docker
        mkdir -p bin && cp ../githttp bin/
        cp -rf ../scripts .

        echo "Copying dependencies"
        copyDep "./bin/githttp"

        echo "Building docker image"
        docker build -t githttp:latest .
    popd
}
