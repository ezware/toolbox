#!/bin/bash

function printVars() {
    for var in "$@"
    do
        eval "echo $var=\$$var"
    done
}

function initVar() {
    local confPath="/host/machine.conf"
    PLATFORM=$(grep onie_platform= < "$confPath" | awk -F= '{print $2}')
    SONIC_VERSION=$(grep build_version < /etc/sonic/sonic_version.yml | awk '{print $2}' | tr -d "[\'\"]"
    )
    PLATFORM_DIR="/host/image-${SONIC_VERSION}/platform/$PLATFORM"
    PLATFORM_DEV_DIR="/usr/share/sonic/device/$PLATFORM"
}

function machineCheck {
    if [ -d "$PLATFORM_DIR" ];
    then
        local debfiles=
        debfiles=$(find "$PLATFORM_DIR/" -type f -name '*.deb' 2>/dev/null | wc -l)
        if ((debfiles > 0));
        then
            echo "Machine check passed."
            return 0
        fi
    fi

    echo "Machine check failed."
    return 1
}

function whlCheck {
    if [ -d "$PLATFORM_DEV_DIR" ]; then
        whlfiles=$(find "${PLATFORM_DEV_DIR}/" -type f -name '*.whl' 2>/dev/null | wc -l)
        if ((whlfiles > 0)); then
            echo "Platform python wheel check passed."
            return 0
        fi
    fi

    echo "Platform python wheel check failed."
    return 1
}

function platformCheck {
    echo "Platform info:"
    find "$PLATFORM_DEV_DIR"
}

function containerAlive() {
    cid=$(docker ps -qfname="$1")
    if [ "$cid" != "" ]; then
        echo "Container $1 ($cid) is alive"
        if [ "$2" != "" ]; then
            docker exec "$1" ps -ef
        fi
    fi
}

function containerSummary() {
    containerAlive syncd
    containerAlive swss
    containerAlive pmon
}

function aliveContainers() {
    docker ps
}

function swssCheck() {
    containerAlive swss v
}

function syncdCheck() {
    echo "Container info:"
    containerAlive syncd v

    echo -e "\nshm size:"
    docker exec syncd df -h | grep shm
    echo ""
}

function pmonCheck() {
    containerAlive pmon v
}

function coreCheck() {
    echo "Core file list:"
    ls -l /var/core
}

function runChecks() {
    for chk in "$@"
    do
        echo -e "** Running check: $chk\n------------------------------"
        eval $chk
        echo "=============================="
    done
}

function sysInfo {
    printVars PLATFORM SONIC_VERSION PLATFORM_DIR PLATFORM_DEV_DIR
}

initVar

runChecks sysInfo platformCheck machineCheck whlCheck containerSummary syncdCheck swssCheck pmonCheck coreCheck aliveContainers
