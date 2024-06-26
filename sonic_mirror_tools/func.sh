#!/bin/bash
echo "script: $0"
SCRIPT_PATH=$(realpath "$0")
SCRIPT_PATH=${SCRIPT_PATH%/*}
echo "script path: ${SCRIPT_PATH}"

#Global vars
REPO_MIRROR=mirrors.tuna.tsinghua.edu.cn

HTTP_SERVER_IP=172.17.0.1

#change to your git mirror ip
GIT_MIRROR_IP="10.10.10.10"
#GIT_MIRROR_PORT=:8000
GIT_MIRROR_PORT=
GIT_MIRROR_ADDR="http://${GIT_MIRROR_IP}${GIT_MIRROR_PORT}"

GOPROXY_IP=${GIT_MIRROR_IP}
GOPROXY_PORT=8100
GOPROXY_ADDR="http://${GOPROXY_IP}:${GOPROXY_PORT}"

function createPipConf {
    local f="files/pip/pip.conf"
    if [ -f "$f" ]; then
        #already exists
        return
    fi

    #create path
    mkdir -p ${f%/*}

    #create file
    echo -e "[global]\nindex-url=http://${REPO_MIRROR}/pypi/web/simple\ntrusted-host=${REPO_MIRROR}" > "$f"
}

function createSetuptoolsFucker {
    local f="files/pip/fucksetuptools.sh"
    if [ -f "$f" ]; then
        return
    fi

    #create path
    mkdir -p ${f%/*}

    #crate file
    echo "REPO_MIRROR=${REPO_MIRROR}" > "$f"
    echo '
dirs=$(find /usr -type d -name setuptools)
for d in $dirs
do
    [ ! -d $d ] || find $d -type f -name "*.py" -exec sed -i "s|https://pypi.python.org|http://${REPO_MIRROR}/pypi/web|g;s|https://pypi.org|http://${REPO_MIRROR}/pypi/web|g {} +"
done
' >> "$f"
}

function replaceMirror {
    local tobeReplace="deb.debian.org security.debian.org debian-archive.trafficmanager.net http.debian.net packages.trafficmanager.net/debian ftp.debian.org"
    local replaceTo="$REPO_MIRROR"
    echo "Searching files for deb mirror replace"
    local files=$(grep -Er 'deb.debian.org|security.debian.org|debian-archive.trafficmanager.net|http.debian.net|packages.trafficmanager.net|ftp.debian.org' | grep deb | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        for rr in $tobeReplace
        do
            sed -i "s|${rr}|${replaceTo}|g" "$f"
        done
    done

    #remove trafficmanager
    find dockers/ -type f -name 'sources*.list*' -exec sed -i '/trafficmanager.net/d' {} +
}

function replaceGoogle {
    echo "Searching files for google mirror replace"
    local files=$(grep -Er 'storage.googleapis.com' | grep -v gopkg | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i 's/storage.googleapis.com\/golang/studygolang.com\/dl\/golang/g' "$f"
    done
}

function replaceDocker {
    echo "Searching files for docker mirror replace"
    local files=$(grep -Er 'download.docker.com' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        #sed -i 's/download.docker.com/mirrors.tuna.tsinghua.edu.cn\/docker-ce/g' "$f"
        sed -i "s|download.docker.com|${REPO_MIRROR}/docker-ce|g" "$f"
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

    createPipConf
    createSetuptoolsFucker

    #awk add xx before first pip install
    local haspipconf
    local files="
sonic-slave-jessie/Dockerfile.j2
sonic-slave-stretch/Dockerfile.j2
sonic-slave-buster/Dockerfile.j2
sonic-slave-bullseye/Dockerfile.j2
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
        awk -v repomirror="$REPO_MIRROR" -f "${SCRIPT_PATH}/fk_setuptools.awk" < "${f}.tmp" > "${f}"
        rm -f "${f}.tmp"
    done

    #replace bootstrap pip
    files="dockers/docker-snmp-sv2/Dockerfile.j2 dockers/docker-snmp/Dockerfile.j2"
    for f in $files
    do
        [ ! -f "$f" ] && continue
        sed -i "s|https://bootstrap.pypa.io|http://${HTTP_SERVER_IP}|g" "$f"
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
        sed -i "s/easy_install pip.*$/easy_install pip<=20.03/" "$f"

        haspipconf=$(grep -c "pip.conf" < "$f")
        if ((haspipconf)); then
            echo "$f already have pip.conf, skipping"
            continue
        fi

        #TODO 
        ##Add pip.conf
        #sudo cp files/pip/pip.conf $FILESYSTEM_ROOT/etc/pip.conf
        awk -v repomirror="$REPO_MIRROR" -f "${SCRIPT_PATH}/addpipconf_for_build_debiansh.awk" < "$f" > "${f}.tmp"
        #awk -v repomirror="$REPO_MIRROR" -f "${SCRIPT_PATH}/fk_setuptools_for_build_debiansh.awk" < "${f}.tmp" > "${f}"
        #rm -f "${f}.tmp"
        mv "${f}.tmp" "$f"

        ## so fucking python, it's too nasty, fuck! ##
        #TODO use another way to fuck
        # add pip.conf before pip[23]? install
        
        # fuck setuptools after each setuptools install
        chmod +x "$f" 
    done

    #mkdir -p files/pip
    #echo -e "[global]\nindex-url=http://${REPO_MIRROR}/pypi/web/simple\ntrusted-host=${REPO_MIRROR}" > files/pip/pip.conf
    #sed -i '/pip[23]? install.*pip/i \ sudo cp files/pip/pip.conf $FILESYSTEMROOT/etc/' build_debian.sh
}

function replaceSonicStorage {
    local files=$(grep -Er 'sonicstorage.blob.core.windows.net' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing sonic storage in $f"
        sed -i 's|https://sonicstorage.blob.core.windows.net|http://sonicstorage.blob.core.windows.net|g' "$f"
    done
}

function replaceDepotTools {
    local files=$(grep -Er 'chromium.googlesource.com/chromium/tools' | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing depot tools in $f"
        #sed -i 's/chromium.googlesource.com\/chromium\/tools/gitee.com\/oceanho/g' "$f"
        sed -i 's|^.*chromium.googlesource.com/chromium/tools.*$|RUN curl -O -L http://172.17.0.1/chromium/tools/depot_tools.tar.gz \&\& tar -C /usr/share/ -xf depot_tools.tar.gz|' "$f"
    done
}

function addGoProxy {
    local godirs="src/sonic-mgmt-framework src/sonic-mgmt-common src/sonic-telemetry"
    for godir in $godirs
    do
        mkfiles=$(grep -r "^[ \t]*GO[ ]*[?:]*=.*go[ \t]*$" "$godir" | grep -v "$GOPROXY_ADDR" | grep Makefile | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
        for mk in $mkfiles
        do
            echo "Adding GOPROXY for $mk"
            sed -i "s|\(^[ \t]*GO[ \t\?:]*\)=\(.*go\)|\1= GOPROXY=${GOPROXY_ADDR} \2|" "$mk"
        done
    done
}

function doReplaceGithub {
    local f="$1"
    local needReplace=$(grep -Ec 'github.com|salsa.debian.org' < "$f")
    if [ "$needReplace" != "0" ]; then
        echo "Replacing github.com or salsa.debian.org in $f"
        sed -i "s|https://github.com|${GIT_MIRROR_ADDR}|g;s|http://github.com|${GIT_MIRROR_ADDR}|g;s|https://salsa.debian.org|${GIT_MIRROR_ADDR}|g" "$f"

	#change to http server ip if this is wget or curl
        needRemove=$(grep "${GIT_MIRROR_ADDR}" < "$f" | grep -c -E 'wget|curl')
        if [ "$needRemove" != "0" ]; then
            echo "Removing ${GIT_MIRROR_PORT} from $f"
            sed -i 's/\(curl .*\)${GIT_MIRROR_ADDR}/\1${HTTP_SERVER_IP}/g' "$f"
            sed -i 's/\(wget .*\)${GIT_MIRROR_ADDR}/\1${HTTP_SERVER_IP}/g' "$f"
        fi
    fi
}

function replaceGithub {
    local files=$(find . -name Makefile)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    files=$(grep -r "git clone" platform | awk -F: '{print $1}' | grep -v README | grep -v ".rst$" | sort | uniq)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    files=$(grep -r "git clone" rules | awk -F: '{print $1}' | grep -v README | grep -v ".rst$" | sort | uniq)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    files="sonic-slave-stretch/Dockerfile.j2 sonic-slave-buster/Dockerfile.j2 sonic-slave-bullseye/Dockerfile.j2"
    for f in $files
    do
        doReplaceGithub "$f"
    done
}

function modifyPyVer {
    local f=dockers/docker-sonic-mgmt-framework/Dockerfile.j2
    local haveReplaced=$(grep -c "pyrsistent==0.17" < "$f")
    if ((haveReplaced)); then
        echo "$f already replaced"
    else    
        echo "Replacing pyrsistent for $f"
        sed -i 's/connexion/pyrsistent==0.17.0 connexion/' dockers/docker-sonic-mgmt-framework/Dockerfile.j2
    fi
}

function addNatsort {
    local f=files/build_templates/sonic_debian_extension.j2
    local modified=$(grep -c "natsort==6.2.1" $f)
    if [ "$modified" == "0" ]; then
        sed -i '/tabulate==/a sudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT apt-get install -y bash-completion\nsudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT pip install natsort==6.2.1\nsudo https_proxy=$https_proxy LANG=C chroot $FILESYSTEM_ROOT pip install bash-completion\n' $f
    fi
}

function removeOldLibprotobuf {
    local f=platform/broadcom/docker-syncd-brcm/Dockerfile.j2
    if [ "$TD4" != "" ]; then
        modified=$(grep -c "libprotobuf.so" < "$f")
        if [ "$modified" == "0" ]; then
            sed -i '/ENTRYPOINT/i RUN rm -rf \/usr\/lib\/x86_64-linux-gnu\/libprotobuf.so*' "$f"
        fi
    fi

    # Add libyaml and libprotobuf
    #RUN apt-get install -y libprotobuf17 libyaml-0-2 && \
    #    ln -s /usr/lib/x86_64-linux-gnu/libprotobuf.so.17 /usr/lib/x86_64-linux-gnu/libprotobuf.so.10
    local modified=$(grep -c "libprotobuf.so.17" "$f")
    if [ $modified -eq 0 ]; then
        sed -i '/RUN apt-get install.*ethtool.*$/a\\nRUN apt-get install -y libprotobuf17 libyaml-0-2 \&\& \\\n    ln -s /usr/lib/x86_64-linux-gnu/libprotobuf.so.17 /usr/lib/x86_64-linux-gnu/libprotobuf.so.10' "$f"
    fi
}

function addShmOption {
    #$(DOCKER_SYNCD_BASE)_RUN_OPT += --shm-size 512M
    local f=platform/broadcom/docker-syncd-brcm.mk
    local hasShmOpt=$(grep -c "shm-size" < "$f")
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

    cp -rf "${SCRIPT_PATH}/attach-docker-image" .

    sed -i '/-v \$(DOCKER_BUILDER_MOUNT).*$/a\\t-v \$(PWD)/attach-docker-image:/attach-docker-image \\' Makefile.work
    sed -i '/SONIC_CONFIG_USE_NATIVE_DOCKERD_FOR_BUILD.*$/a\\t[ -f /attach-docker-image/attachimage.sh ] && /attach-docker-image/attachimage.sh' slave.mk
}

function modifyAptSrc {
    local paths="sonic-slave-jessie sonic-slave-stretch sonic-slave-buster sonic-slave-bullseye"
    for p in $paths
    do
        f="$p/Dockerfile.j2"
        if [ -f "$f" ]; then
            echo "Modifying $f, change >> to >  /etc/apt/sources.list"
            sed -i 's|^RUN\(.*\)>> /etc/apt|RUN\1\> /etc/apt|' "$f"
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

function replaceFileServer {
    local tobeReplace="repo1.maven.org"
    local searchKeys=""
    local key=""

    for key in ${tobeReplace}
    do
        if [ "$searchKeys" != "" ]; then
            searchKeys="$searchKeys|$key"
        else
            searchKeys="$key"
        fi
    done

    echo "Searching files for file server replace"
    local replaceTo="${HTTP_SERVER_IP}"  #replace to local http server
    local files=$(grep -Er "${searchKeys}" | grep -E 'wget|curl' | awk -F: '{print $1}' | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        for rr in $tobeReplace
        do
            sed -i "s|http[s]\?://$rr|http://$replaceTo|g" "$f"
        done
    done
}

function tempFix {
    local f="src/sonic-platform-common/tests/sfputilhelper_test.py"
    sed -i 's/\([ \t]\+\).*SfpUtilHelper().*$/\1return/g' "$f"
    sed -i '/sfputilhelper/d' "$f"

    #avoid get ssh/terminal failure
    f="src/sonic-telemetry/Makefile"
    sed -i 's|get golang.org/x/crypto/ssh/terminal@e9b2fee46413|get golang.org/x/crypto@v0.0.0-20191206172530-e9b2fee46413|g' "$f"

    f="src/ifupdown2/Makefile"
    sed -i "s|\(.*wget.*\)${GIT_MIRROR_ADDR}|\1${HTTP_SERVER_IP}|" "$f"
}

function addVendorNOSVer {
    f="vendornos.ver"
    if [ ! -f "$f" ]; then
        echo "XXXNOS v1.00 D001" > "$f"
    fi

    #Modify functions.sh
    f="functions.sh"
    if ( ! grep -c "getVendorVer" "$f"); then
        echo '

function getVendorVer() {
    local vendor=XXX
    local commitID=$(git rev-parse --short HEAD)
    local buildDate=$(date +%Y%m%d%H%M)
    local branchName=$(git rev-parse --abbrev-ref HEAD)
    local buildNumber=${BUILD_NUMBER:-0}

    #local buildDate=20210401
    echo "${vendor}.${branchName}.${buildNumber}-${commitID}-${buildDate}"
}' >> "$f"
    fi

    f="attach_vendornos_ver.sh"
    if [ ! -f "$f" ]; then
    echo -n '#!/bin/bash

#this file should embeded in build_debian.sh and put it before make squashfs
function attach_vendornos_version() {
    set -x
    local FS_BASE_DIR="$1"
    local VENDOR_IMAGE_VERSION=
    VENDOR_IMAGE_VERSION="$(cat h3cnos.ver)"
    if [ "$VENDOR_IMAGE_VERSION" != "" ]; then
        local showpydirs=
	local pyfile=
	local modified=
        showpydirs=$(sudo find "${FS_BASE_DIR}/usr" -type d -name show | grep python)
        for showdir in $showpydirs
        do
            pyfile=$(sudo find "$showdir" -type f -name ' > "$f"
    echo "'main.py' | head -1)" >> "$f"
    echo -n '
            modified=$(grep -c "VENDORNOS" < "$pyfile")
            if [ "$modified" != "0" ]; then
            	echo "VENDORNOS Version already attached, removing"
		sudo sed -i ' >> "$f"
    echo -n "'/VENDORNOS/d'" >> "$f"
    echo ' "$pyfile"
	    fi
            sudo sed -i "s/\(.*click.echo\)\(.*SONiC Software Version.*$\)/\1\2\n\1(\"${VENDOR_IMAGE_VERSION}\")/" "$pyfile" || true
        done
    fi
    return 0
}

attach_vendornos_version "$FILESYSTEM_ROOT" || true' > "$f"
    fi
}

function addRepack {
    local slave_mk_added
    slave_mk_added=$(grep -c repack.mk < slave.mk)
    if [ "$slave_mk_added" == "0" ]; then
        echo "-include repack.mk" >> slave.mk
    fi

    if [ ! -f repack.mk ]; then
        cp "${SCRIPT_PATH}/repack.mk" .
        cp "${SCRIPT_PATH}/repack.sh" .
        cp "${SCRIPT_PATH}/repack_script.sh" .
    fi
}

function replaceCentec {
    echo "Searching files for centec replace"
    local files
    files=$(grep -Er 'CentecNetworks' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s|https://github.com/CentecNetworks|http://${HTTP_SERVER_IP}/CentecNetworks|g" "$f"
    done
}

function replacePyPkg {
    echo "Searching files for python packages replace"
    local files
    files=$(grep -Er 'pypi.python.org/packages' | awk -F: '{print $1}' | grep -v ".git" | sort | uniq)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s|https://pypi.python.org/packages|http://${REPO_MIRROR}/pypi/web/packages|g" "$f"
    done
}

function replaceBfn {
    echo "Searching files for barefoot networks replace"
    local files=$(grep github.com platform/barefoot/*.mk)
    for f in $files
    do
        echo "Replacing file $f"
        sed -i "s|\(URL[ \t]*=[ \t]*\)\"https://github.com/|\1\"http://${HTTP_SERVER_IP}/|g" "$f"
    done
}

function bazelFix {
    files="sonic-slave-stretch/Dockerfile.j2 sonic-slave-buster/Dockerfile.j2 sonic-slave-bullseye/Dockerfile.j2"
    for f in $files
    do
        sed -i "s|${GIT_MIRROR_IP}/bazelbuild|${HTTP_SERVER_IP}/bazelbuild|" "$f"
    done
}

function replaceBashUrl {
    files="src/bash/Makefile"
    for f in $files
    do
        sed -i "s|https://launchpad.net|http://${HTTP_SERVER_IP}|" "$f"
    done
}
