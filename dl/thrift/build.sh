#!/bin/bash
rm -rf gen-go gen-js
thrift --gen js --gen go dl.thrift
pushd gen-go/dl
    rm -rf go.sum go.mod
    go mod init
    myproxy go mod tidy
    sed -i "s/thrift v0.15.0/thrift v$(thrift --version | awk '{print $NF}')/g" go.mod
    myproxy go mod tidy
popd
