#!/bin/bash

gits=$(find . -type d -name '*.git')
for gitrepo in $gits
do
    pushd $gitrepo
        echo "Updating $gitrepo"
        git remote update
    popd
done

