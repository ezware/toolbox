#!/bin/bash

REPO_MIRROR=10.153.3.130

function replaceKernelArchiveURL {
	#files=(grep -r www.kernel.org | grep K_ARCHIVE_URL | awk -F: '{print $1}' | sort | uniq)
	sed -i 's|https://www.kernel.org|http://172.17.0.1|' make/kbuild.mk
}

function changeDebianMirror {
	sed -i "s/archive.debian.org/${REPO_MIRROR}/;s/mirrors.kernel.org/${REPO_MIRROR}/" tools/onlrfs.py
}

function removeAptCache {
	sed -i 's|127.0.0.1:3142/||' tools/onlrfs.py
}

#apt-mirror
#apt.opennetlinux.org/debian

WORKDIR=$1
pushd $WORKDIR
	replaceKernelArchiveURL
	changeDebianMirror
	removeAptCache
popd
