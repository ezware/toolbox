GIT_MIRROR="http://172.17.0.1:8000"

replaceTianoUrl {
    local f=payloads/external/tianocore/Makefile
    sed -i 's|\(^[\t ]*\)\(git submodule update\)|\1sed -i "s\|https://github.com\|http://172.17.0.1:8000\|g" .gitmodules; \\n\1\2/g' "$f"
}

replaceGrubUrl {
    local f=payloads/external/GRUB2/Makefile
    sed -i "s|./bootstrap|GNULIB_URL=http://172.17.0.1:8000/coreutils/gnulib ./bootstrap|" "$f"
}
