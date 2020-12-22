#!/bin/bash

function loadBuster {
debianBuster=$(docker images debian:buster | grep -v REPO)

if [ "$debianBuster" == "" ]; then
    echo "Loading debian:buster"
    docker load -i /attach-docker-image/debian10.tar.gz
    docker tag debian:buster debian:10
fi
}

function loadStretch {
debianStretch=$(docker images debian:stretch | grep -v REPO)

if [ "$debianStretch" == "" ]; then
    echo "Loading debian:stretch"
    docker load -i /attach-docker-image/debian9.tar.gz
    docker tag debian:stretch debian:9
fi
}

function loadJessie {
debianJessie=$(docker images debian:jessie | grep -v REPO)
if [ "$debianJessie" == "" ]; then
    echo "Loading debian:jessie"
    docker load -i /attach-docker-image/debian8.tar.gz
    docker tag debian:jessie debian:8
fi
}

service docker status
docker images
loadStretch
loadBuster
