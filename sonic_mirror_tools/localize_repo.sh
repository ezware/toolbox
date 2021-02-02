#!/bin/bash
#localize the sonic repo

# url = https://github.com/Azure/sonic-wpa-supplicant.git

if [ "$1" == "" ]; then
    echo "Usage: $0 path-to-sonic-buildimage"
    exit 0
fi

WORKDIR=$1

pushd $WORKDIR
    #replace first level
    replaced=$(grep -c "url = http://172" < .gitmodules)
    if [ "$replaced" == "0" ]; then
        echo "replacing git url"
        sed -i 's|url = https://github.com|url = http://172.17.0.1:8000|g' .gitmodules
    else
        echo "git url has been replaced"
    fi

    #change init behavior
    changed=$(grep -c "src/sonic-sairedis/.gitmodules" < Makefile.work)
    if [ "$changed" == "0" ]; then
        echo "changing init behavior"
        sed -i "/^init[ ]*:/a\\\t@git submodule update --init\n\t@sed -i 's|url = https://github.com|url = http://172.17.0.1:8000|g' src/sonic-sairedis/.gitmodules platform/p4/SAI-P4-BM/.gitmodules\n\t@pushd src/sonic-sairedis; git submodule update --init; sed -i 's|url = https://github.com|url = http://172.17.0.1:8000|g' SAI/.gitmodules; popd" Makefile.work
    else
        echo "behavior already changed"
    fi
popd

