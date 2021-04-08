#!/bin/bash

function repack_it() {
    sudo cp target/debs/buster/platform-modules-xxx_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-xxx-r0/
    sudo dpkg --root=$FILESYSTEM_ROOT -r sonic-device-data-xxx || true
    sudo dpkg --root=$FILESYSTEM_ROOT -i target/debs/buster/sonic-device-data-xxx_1.0_all.deb
}

repack_it || true
