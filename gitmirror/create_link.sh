repohomes=$(ls -1)

for repohome in $repohomes
do
    if [ ! -d "$repohome" ]; then
        continue
    fi

    pushd "$repohome"
        repos=$(ls -1)
        for repo in $repos
        do
            #create link
        done
    popd
done
