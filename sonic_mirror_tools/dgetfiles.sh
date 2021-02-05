#!/bin/bash
dget_urls="
https://sonicstorage.blob.core.windows.net/debian/pool/main/l/lldpd/lldpd_1.0.4-1.dsc
https://sonicstorage.blob.core.windows.net/debian/pool/main/n/net-snmp/net-snmp_5.7.3+dfsg-5.dsc
https://sonicstorage.blob.core.windows.net/debian/pool/main/liby/libyang/libyang_1.0.184-2.dsc
"

dest_root=/www

#$1 URL
function getit() {
    local geturl="$1"
    local filepath="${geturl#*//*/}"
    local filename="${filepath##*/}"
    filepath="${filepath%/*}"
    local destpath="${dest_root}/${filepath}"
    local fullfilepath="${destpath}/${filename}"

    if [ ! -d "${destpath}" ]; then
        echo "Creating dir ${destpath}"
        mkdir -p "${destpath}"
    fi

    if [ ! -f "$fullfilepath" ]; then
        echo "Downloading $filename to $fullfilepath from $geturl"
        pushd "$destpath"
            myproxy dget -u -d "$geturl"
        popd
    else
        echo "$fullfilepath already exist, skipping"
    fi
}

which dget
if [ ! $? -eq 0 ]; then
    echo "No dget, trying to get it"
    sudo apt-get install -y devscripts
fi

for url in $dget_urls
do
    getit $url
done

