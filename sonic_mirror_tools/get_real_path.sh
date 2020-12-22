scriptPath=$(realpath $0)
scriptPath=${scriptPath%/*}
function getpath {
echo "ScriptPath: ${scriptPath}/printfield.awk" >&2
echo "WorkPath: $(pwd)" >&2
#get kernel path
kernel_procure_method=1234 make --dry-run -f src/sonic-linux-kernel/Makefile | grep sonicstorage | awk -f "${scriptPath}/printfield.awk" '{printfield("sonicstorage")}'
kernel_procure_method=1234 make --dry-run -f src/sonic-linux-kernel/Makefile | grep "172.17.0.1" | awk '{ print $5 }'

#get python path
makefiles="src/python3/Makefile"
for mkfile in $makefiles
do
    echo "getting path from $mkfile" >&2
    make --dry-run -f "$mkfile"  | grep sonicstorage | awk '{for (i=1; i<NF; i++){if ($i~/172/) {print $i} }}'
    make --dry-run -f "$mkfile"  | grep 172.17.0.1 | awk '{for (i=1; i<NF; i++){if ($i~/172/) {print $i} }}'
done

#get smartmontools path
make -f ${scriptPath}/smartmontools.mk all
}

pushd $1 >&2
    getpath
popd >&2
