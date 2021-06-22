#!/bin/bash

function repack_it() {
    local oem=xxx
    local products='sxxxx-48xx8x-w1 sxxxx-24x8x-w1 sxxxx-64x-w1 xy200x0'
    local p=

    for p in $products
    do
        sudo mkdir -p ${FILESYSTEM_ROOT}/platform/x86_64-${oem}_${p}-r0/
        sudo cp target/debs/buster/platform-modules-${oem}-${p}_1.0_amd64.deb ${FILESYSTEM_ROOT}/platform/x86_64-${oem}_${p}-r0/
    done

    sudo dpkg --root=$FILESYSTEM_ROOT -r sonic-device-data-xxx || true
    sudo dpkg --root=$FILESYSTEM_ROOT -i target/debs/buster/sonic-device-data-xxx_1.0_all.deb
}

repack_it || true
