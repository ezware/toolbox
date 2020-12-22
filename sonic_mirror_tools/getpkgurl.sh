
function geturl {
    grep -r "sonicstorage.blob.core.windows.net" | awk '{for (i=1; i <= NF; i++){if ($i ~/sonicstorage.blob.core.windows.net/){print $i}}}' | sed 's/^.*BASE_URL=//' | sed "s/^'//g;s/'$//g;s/^\"//g;s/\"$//g" | sort | uniq | grep -vE 'PYTHON_VER|KERNEL_VERSION|SMARTMONTOOLS_VERSION'
}

pushd $1 >&2
    geturl
popd >&2
