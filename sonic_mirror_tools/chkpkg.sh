debugon=0
if [ "$1" == "D" ]; then
    debugon=1
    shift
fi

if [ "$1" != "" ]; then
    pkgfile=$1
else
    pkgfile=pkgs.txt
fi

pkgs=$(cat "$pkgfile")
for pkg in $pkgs
do
    testpkg=${pkg/https/http}
    if [ "$debugon" != "0" ]; then
        echo -e "Testing pkg ${pkg}\n       from  $testpkg"
    fi

    notexist=$(curl --head ${testpkg} 2>/dev/null | grep -c "Not Found")
    if [ "$notexist" != "0" ]; then
        if [ "$debugon" != "0" ]; then
            echo "NOT==$pkg"
        else
            echo "$pkg"
        fi
    else
        if [ "$debugon" != "0" ]; then
            echo "YES**$pkg"        
        fi
    fi
done

