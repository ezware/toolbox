#!/bin/bash

PKG_NAME=platform-modules-fky-s6850-56hf_1.0_amd64.deb
#PKG_NAME=platform-modules-fky-s9855-48cd8d-w1_1.0_amd64.deb

#rebuild platform
echo "Cleaning"
rm -f target/sonic-broadcom.bin
rm -f target/debs/buster/platform-modules-fky-*

pushd platform/broadcom/sonic-platform-modules-fky/
./clean.sh
popd
NOSTRETCH=1 USERNAME=admin PASSWORD=admin make target/debs/buster/${PKG_NAME}-clean

echo "Building platform..."
NOSTRETCH=1 USERNAME=admin PASSWORD=admin make target/debs/buster/${PKG_NAME}

echo "Repacking..."
NOSTRETCH=1 USERNAME=admin PASSWORD=admin make repack

echo "Done"
