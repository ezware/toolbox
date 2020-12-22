
function doReplaceGithub {
    f="$1"
        needRelace=$(grep -Ec 'github.com|salsa.debian.org' < "$f")
        if [ "$needReplace" != "0" ]; then
            echo "Replacing github.com or salsa.debian.org in $f"
            sed -i 's/https:\/\/github.com/http:\/\/172.17.0.1:8000/g;s/http:\/\/github.com/http:\/\/172.17.0.1:8000/g;s/https:\/\/salsa.debian.org/http:\/\/172.17.0.1:8000/g' "$f"
        fi
}

function replaceGithub {
    files=$(find . -name Makefile)
    for f in $files
    do
        doReplaceGithub "$f"
    done

    dirs="platform rules"
    for d in $dirs
    do
        files=$(grep -r "git clone" "$d" | grep -v README.md | grep -v "\.txt" | awk -F: '{print $1}' | sort | uniq)
        for f in $files
        do
            doReplaceGithub "$f"
        done
    done
}

pushd $1
    replaceGithub

popd
