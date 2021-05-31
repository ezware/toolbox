#!/bin/bash
## This script is to automate the preparation for a debian file system, which will be used for
## an ONIE installer image.
##
## USAGE:
##   USERNAME=username PASSWORD=password ./build_debian
## ENVIRONMENT:
##   USERNAME
##          The name of the default admin user
##   PASSWORD
##          The password, expected by chpasswd command

## Default user
[ -n "$USERNAME" ] || {
    echo "Error: no or empty USERNAME"
    exit 1
}

## Password for the default user
[ -n "$PASSWORD" ] || {
    echo "Error: no or empty PASSWORD"
    exit 1
}

## Include common functions
. functions.sh

## Enable debug output for script
set -x -e

CONFIGURED_ARCH=$([ -f .arch ] && cat .arch || echo amd64)

## docker engine version (with platform)
LINUX_KERNEL_VERSION=4.19.0-12-2

## Working directory to prepare the file system
FILESYSTEM_ROOT=./fsroot
PLATFORM_DIR=platform
## Hostname for the linux image
HOSTNAME=sonic

## Read ONIE image related config file
. ./onie-image.conf
[ -n "$ONIE_IMAGE_PART_SIZE" ] || {
    echo "Error: Invalid ONIE_IMAGE_PART_SIZE in onie image config file"
    exit 1
}
[ -n "$ONIE_INSTALLER_PAYLOAD" ] || {
    echo "Error: Invalid ONIE_INSTALLER_PAYLOAD in onie image config file"
    exit 1
}
[ -n "$FILESYSTEM_SQUASHFS" ] || {
    echo "Error: Invalid FILESYSTEM_SQUASHFS in onie image config file"
    exit 1
}

## Prepare the file system directory
if [[ ! -d $FILESYSTEM_ROOT ]]; then
    die "No file system root: $FILESYSTEM_ROOT"
fi

TARGET_BIN="target/sonic-broadcom.bin"
[ -f $FILESYSTEM_SQUASHFS ] && rm -f $FILESYSTEM_SQUASHFS
[ -f $FILESYSTEM_DOCKERFS ] && rm -f $FILESYSTEM_DOCKERFS
[ -f "${TARGET_BIN}" ] && rm -f "${TARGET_BIN}"

REPACK_SCRIPT=repack_script.sh
if [ -f "$REPACK_SCRIPT" ];
then
    . $REPACK_SCRIPT
else
    echo "No repack script $REPACK_SCRIPT"
fi

## Output the file system total size for diag purpose
## Note: -x to skip directories on different file systems, such as /proc
sudo du -hsx $FILESYSTEM_ROOT
sudo mkdir -p $FILESYSTEM_ROOT/var/lib/docker

# update version to /etc/sonic/sonic_version.yml
SONIC_VER_UPDATE=$(sonic_get_version)
sudo sed -i "s/\(.*build_version:\).*$/\1 '${SONIC_VER_UPDATE}'/" "$FILESYSTEM_ROOT/etc/sonic/sonic_version.yml"

# attach H3CNOS version
. attach_h3cnos_ver.sh

sudo mksquashfs $FILESYSTEM_ROOT $FILESYSTEM_SQUASHFS -e boot -e var/lib/docker -e $PLATFORM_DIR

#scripts/collect_host_image_version_files.sh $TARGET_PATH $FILESYSTEM_ROOT

if [[ $CONFIGURED_ARCH == armhf || $CONFIGURED_ARCH == arm64 ]]; then
    # Remove qemu arm bin executable used for cross-building
    sudo rm -f $FILESYSTEM_ROOT/usr/bin/qemu*static || true
    DOCKERFS_PATH=../dockerfs/
fi

## Compress docker files
pushd $FILESYSTEM_ROOT && sudo tar czf $OLDPWD/$FILESYSTEM_DOCKERFS -C ${DOCKERFS_PATH}var/lib/docker .; popd

## Compress together with /boot, /var/lib/docker and $PLATFORM_DIR as an installer payload zip file
pushd $FILESYSTEM_ROOT && sudo zip $OLDPWD/$ONIE_INSTALLER_PAYLOAD -r boot/ $PLATFORM_DIR/; popd
sudo zip -g -n .squashfs:.gz $ONIE_INSTALLER_PAYLOAD $FILESYSTEM_SQUASHFS $FILESYSTEM_DOCKERFS
