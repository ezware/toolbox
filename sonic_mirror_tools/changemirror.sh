#!/bin/bash

WORKDIR=./
SCRIPT_PATH=$(realpath "$0")
SCRIPT_PATH=${SCRIPT_PATH%/*}

REPO_MIRROR=mirrors.tuna.tsinghua.edu.cn

if [ "$1" != "" ]; then
    WORKDIR=$1
fi

function replaceMirror {
    tobeReplace="deb.debian.org security.debian.org debian-archive.trafficmanager.net http.debian.neti packages.trafficmanager.net/debian"
    replaceTo="$REPO_MIRROR"
    echo "Searching files for deb mirror replace"
    files=$(grep -Er 'deb.debian.org|security.debian.org|debian-archive.trafficmanager.net|http.debian.net|packages.trafficmanager.net' | grep deb | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        for rr in $tobeReplace
        do
            sed -i "s|$rr|$replaceTo|g" "$f"
        done
    done
}

function replaceGoogle {
    echo "Searching files for google mirror replace"
    files=$(grep -Er 'storage.googleapis.com' | grep -v gopkg | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i 's/storage.googleapis.com\/golang/studygolang.com\/dl\/golang/g' "$f"
    done
}

function replaceDocker {
    echo "Searching files for docker mirror replace"
    files=$(grep -Er 'download.docker.com' | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        #sed -i 's/download.docker.com/mirrors.tuna.tsinghua.edu.cn\/docker-ce/g' "$f"
        sed -i "s/download.docker.com/${REPO_MIRROR}\\/docker-ce/g" "$f"
    done
}

function replacePypi {
#add pypi mirror before using pip
 #sonic-buildimage/sonic-slave-jessie/Dockerfile.j2
 #sonic-buildimage/sonic-slave-stretch/Dockerfile.j2
 #sonic-buildimage/dockers/docker-base/Dockerfile.j2
 #sonic-buildimage/dockers/docker-base-stretch/Dockerfile.j2
 #dockers/docker-config-engine-stretch/Dockerfile.j2

#RUN echo "[global]" > /etc/pip.conf \
#    && echo "index-url=http://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple" >> /etc/pip.conf \
#    && echo "trusted-host=mirrors.tuna.tsinghua.edu.cn" >> /etc/pip.conf \
#    && mkdir -p /root/.pip && cp /etc/pip.conf /root/.pip/

#RUN find /usr/lib/python2.7/dist-packages/setuptools/ -type f -name '*.py' | xargs sed -i 's/https:\/\/pypi.python.org/http:\/\/10.153.3.130\/pypi\/web/g;s/https:\/\/pypi.org/http:\/\/10.153.3.130\/pypi\/web/g' && find /usr/lib/python3/dist-packages/setuptools/ -type f -name '*.py' | xargs sed -i 's/https:\/\/pypi.python.org/http:\/\/10.153.3.130\/pypi\/web/g;s/https:\/\/pypi.org/http:\/\/10.153.3.130\/pypi\/web/g'

#dockers/docker-snmp-sv2/Dockerfile.j2
##RUN curl https://bootstrap.pypa.io/get-pip.py | python3.6
#RUN apt-get install -y python3-pip && pip3 install -U pip

    #awk add xx before first pip install
    files="
sonic-slave-jessie/Dockerfile.j2
sonic-slave-stretch/Dockerfile.j2
sonic-slave-buster/Dockerfile.j2
dockers/docker-base/Dockerfile.j2
dockers/docker-base-stretch/Dockerfile.j2
dockers/docker-base-buster/Dockerfile.j2
dockers/docker-config-engine-stretch/Dockerfile.j2
"
    for f in $files
    do
        if [ ! -e "$f" ]; then
            echo "$f not exist, skipping"
            continue
        fi
    
        haspipconf=$(grep -c "/etc/pip.conf" < "$f")
        if ((haspipconf)); then
            echo "$f already have pip.conf, skipping"
            continue
        fi

        echo "Adding pip.conf for $f"
        awk -v repomirror="$REPO_MIRROR" -f "${SCRIPT_PATH}/addpipconf.awk" < "$f" > "${f}.tmp"
        mv "${f}.tmp" "$f"
    done

    #replace bootstrap pip
    files="dockers/docker-snmp-sv2/Dockerfile.j2"
    for f in $files
    do
        sed -i 's/https:\/\/bootstrap.pypa.io/http:\/\/172.17.0.1/g' "$f"
    done

    #replace easy_install pip 
    files="build_debian.sh"
    for f in $files
    do
        haspipconf=$(grep -c "pip.conf" < "$f")
        if ((haspipconf)); then
            echo "$f already have pip.conf, skipping"
            continue
        fi

        echo "Adding pip.conf and install pip for $f"
        awk -v repomirror="$REPO_MIRROR" -f "${SCRIPT_PATH}/replace_easy_install.awk" < "$f" > "${f}.tmp"
        mv "${f}.tmp" "$f"
        chmod +x "$f"
    done

    #TODO: add pip.conf in build_debian.sh for new master branch

}

function replaceSonicStorage {
    files=$(grep -Er 'sonicstorage.blob.core.windows.net' | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing sonic storage in $f"
        sed -i 's/https:\/\/sonicstorage.blob.core.windows.net/http:\/\/sonicstorage.blob.core.windows.net/g' "$f"
    done
}

function replaceDepotTools {
    files=$(grep -Er 'chromium.googlesource.com/chromium/tools' | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing depot tools in $f"
        #sed -i 's/chromium.googlesource.com\/chromium\/tools/gitee.com\/oceanho/g' "$f"
        sed -i 's/^.*chromium.googlesource.com\/chromium\/tools.*$/RUN curl -O -L http:\/\/172.17.0.1\/chromium\/tools\/depot_tools.tar.gz \&\& tar -C \/usr\/share\/ -xf depot_tools.tar.gz/' "$f"
    done
}

function addGolangProxy {
#
#GOPROXY="https://goproxy.cn" $(GO)
    echo "TODO: auto add goproxy"
}

function doReplaceGithub {
    f="$1"
    needReplace=$(grep -Ec 'github.com|salsa.debian.org' < "$f")
    if [ "$needReplace" != "0" ]; then
        echo "Replacing github.com or salsa.debian.org in $f"
        sed -i 's/https:\/\/github.com/http:\/\/172.17.0.1:8000/g;s/http:\/\/github.com/http:\/\/172.17.0.1:8000/g;s/https:\/\/salsa.debian.org/http:\/\/172.17.0.1:8000/g' "$f"

        #remove :8000 if this is wget or curl
        needRemove=$(grep "172.17.0.1:8000" < "$f" | grep -c -E 'wget|curl')
        if [ "$needRemove" != "0" ]; then
            sed -i 's/\(curl .*\)172.17.0.1:8000/\1172.17.0.1/g' $f
            sed -i 's/\(wget .*\)172.17.0.1:8000/\1172.17.0.1/g' $f
        fi
    fi
}

function replaceGithub {
    files=$(find . -name Makefile)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    files=$(grep -r "git clone" platform | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    files=$(grep -r "git clone" rules | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    doReplaceGithub sonic-slave-buster/Dockerfile.j2
}

function modifyPyVer {
    f=dockers/docker-sonic-mgmt-framework/Dockerfile.j2
    haveReplaced=$(grep -c "pyrsistent==0.17" < "$f")
    if ((haveReplaced)); then
        echo "$f already replaced"
    else    
        echo "Replacing pyrsistent for $f"
        sed -i 's/connexion/pyrsistent==0.17.0 connexion/' dockers/docker-sonic-mgmt-framework/Dockerfile.j2
    fi
}

function addNatsort {
    f=files/build_templates/sonic_debian_extension.j2
    modified=$(grep -c "natsort==6.2.1" $f)
    if [ "$modified" == "0" ]; then
        sed -i '/tabulate==/a sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT apt-get install -y bash-completion\nsudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT pip install natsort==6.2.1\nsudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT pip install bash-completion\n' $f
    fi
}

function removeOldLibprotobuf {
    f=platform/broadcom/docker-syncd-brcm/Dockerfile.j2
    if [ "$TD4" != "" ]; then
        modified=$(grep -c "libprotobuf.so" < "$f")
        if [ "$modified" == "0" ]; then
            sed -i '/ENTRYPOINT/i RUN rm -rf \/usr\/lib\/x86_64-linux-gnu\/libprotobuf.so*' "$f"
        fi
    fi
}

function addShmOption {
    #$(DOCKER_SYNCD_BASE)_RUN_OPT += --shm-size 512M
    f=platform/broadcom/docker-syncd-brcm.mk
    hasShmOpt=$(grep -c "shm-size" < "$f")
    if [ "$hasShmOpt" == "0" ]; then
        echo "Adding shm-size option to $f"
        echo "\$(DOCKER_SYNCD_BASE)_RUN_OPT += --shm-size 512M" >> "$f"
    fi
}

function addDockerAttachment {
    if [ -d attach-docker-image ]; then
        return
    fi

    echo "Adding docker attachment"

    cp -rf ${SCRIPT_PATH}/attach-docker-image .

    sed -i '/-v \$(DOCKER_BUILDER_MOUNT).*$/a\\t-v \$(PWD)/attach-docker-image:/attach-docker-image \\' Makefile.work
    sed -i '/SONIC_CONFIG_USE_NATIVE_DOCKERD_FOR_BUILD.*$/a\\t[ -f /attach-docker-image/attachimage.sh ] && /attach-docker-image/attachimage.sh' slave.mk
}

function modifyAptSrc {
    paths="sonic-slave-jessie sonic-slave-stretch sonic-slave-buster"
    for p in $paths
    do
        f="$p/Dockerfile.j2"
        if [ -f "$f" ]; then
            echo "Modifying $f, change >> to >  /etc/apt/sources.list"
            sed -i 's|^RUN\(.*\)>> /etc/apt|RUN\1\> /etc/apt|' $f
        fi
    done
}

function removeNoCacheIndicator {
    sed -i 's/docker build --no-cache/docker build/' Makefile.work
}

function replaceGPGURL {
    #make sure download public_key.gpg from original url first and put it to www/packages/debian/
    sed -i 's|\(TRUSTED_GPG_URLS[ ]*=[ ]*http\).*$|\1://172.17.0.1/packages/debian/public_key.gpg|' rules/config
}

pushd "$WORKDIR"
    replaceMirror 
    replaceGoogle
    replaceDocker
    replacePypi
    replaceSonicStorage
    replaceDepotTools
    replaceGithub
    modifyPyVer
    removeOldLibprotobuf
    addShmOption
    addNatsort
    addDockerAttachment
    modifyAptSrc
    removeNoCacheIndicator
    replaceGPGURL
popd

echo "Adapting local mirror"
${SCRIPT_PATH}/tolocalmirror.sh "$WORKDIR"
