#！/bin/bash

#$1 base command list, split by white space, e.g. "show config", optional, default is "show config"
#$2 outpath, optional, default is ./
BASE_CMD_LIST="show config"
OUT_PATH=./

if [ "$1" != "" ]; then
	BASE_CMD_LIST="$1"
fi

if [ "$2" != "" ]; then
	OUT_PATH="$2"
fi

#$1 base command
function getCommands() {
    local baseCmd="$1"
    local subCmd=
    local subCmdList=

    hasSubCmd=$($baseCmd | grep -c 'Commands:')
    if ((hasSubCmd)); then
	    subCmdList=$($baseCmd | awk 'BEGIN{sp=0}{ if (sp == 1) { print $1 } if ((sp == 0) && ($1 == "Commands:")) {sp = 1}}')
	    for subCmd in $subCmdList
	    do
	    	echo $baseCmd $subCmd
	    	getCommands "$baseCmd $subCmd"
	    done
	fi
}

mkdir -p ${OUT_PATH}
cmdFile="${OUT_PATH}/cmdtree.txt"
touch $cmdFile
if [ ! $? -eq 0 ]; then
	echo "Failed to create output file $cmdFile"
	exit 1
fi

for bc in $BASE_CMD_LIST
do
	getCommands "$bc" >$cmdFile
done
