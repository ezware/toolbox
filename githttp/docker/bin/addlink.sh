curdir=$(pwd)
cd /bin
apps=$(busybox --list)

for app in $apps
do
    if [ ! -e $app ]; then
        ln -s busybox $app
    fi
done

cd $curdir


