#!/bin/bash

function repack_it() {
    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9855-48cd8d-w1-r0/
    sudo cp target/debs/buster/platform-modules-fky-s9855-48cd8d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9855-48cd8d-w1-r0/

    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9855-24c8d-w1-r0/
    sudo cp target/debs/buster/platform-modules-fky-s9855-24c8d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9855-24c8d-w1-r0/

    sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9825-64d-w1-r0/
    sudo cp target/debs/buster/platform-modules-fky-s9825-64d-w1_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-fky_s9825-64d-w1-r0/

    sudo dpkg --root=$FILESYSTEM_ROOT -r sonic-device-data-fky || true
    sudo dpkg --root=$FILESYSTEM_ROOT -i target/debs/buster/sonic-device-data-fky_1.0_all.deb
}

repack_it || true
