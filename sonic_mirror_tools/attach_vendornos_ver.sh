#!/bin/bash

#this file should embeded in build_debian.sh and put it before make squashfs
function attach_vendornos_version() {
    set -x
    local FS_BASE_DIR="$1"
    local VENDOR_IMAGE_VERSION=
    VENDOR_IMAGE_VERSION="$(cat vendornos.ver)"
    if [ "$VENDOR_IMAGE_VERSION" != "" ]; then
        local showpydirs=
	local pyfile=
	local modified=
        showpydirs=$(sudo find "${FS_BASE_DIR}/usr" -type d -name show | grep python)
        for showdir in $showpydirs
        do
            pyfile=$(sudo find "$showdir" -type f -name 'main.py' | head -1)
            modified=$(grep -c "XXXNOS" < "$pyfile")
            if [ "$modified" == "0" ]; then
                sudo sed -i "s/\(.*click.echo\)\(.*SONiC Software Version.*$\)/\1\2\n\1(\"${VENDOR_IMAGE_VERSION}\")/" "$pyfile" || true
            else                                                                                               echo "XXXNOS Version already attached"
            fi
        done
    fi
    return 0
}

attach_vendornos_version "$FILESYSTEM_ROOT" || true
