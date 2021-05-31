#!/bin/bash

function checkAttrNull() {
files=$(grep -Er "struct[ ]+attribute " | awk -F: '{print $1}' | sort | uniq)

for f in $files
do
    if [ ! -f "$f" ]; then
        continue
    fi

    echo "Checking file: $f"

    awk 'BEGIN {
            #0: find begin
            #1: find end
            state = 0
            haveNull = 0
            curSt = ""
            ln = 0
            badCnt = 0
            lastLine = ""
        }
        {
            ln++

            if ((state == 0) && ($0 ~ /struct[ ]+attribute /))
            {
                state = 1
                curSt = sprintf("%d: %s", ln, $0)
                haveNull = 0
            }

            if (state == 1)
            {
                if ($1 ~/NULL[};]*/)
                {
                    haveNull++
                }

                if ($1 ~/\}[ ]*[;]*/)
                {
                    state = 0
                    if (haveNull) {
                        printf("V OK: %s, NULL count: %d, end line: %d\n", curSt, haveNull, ln)
                    } else {
                        printf("X No NULL: %s, end line: %d\n  lastLine: %s\n  curLine: %s\n", curSt, ln, lastLine, $0)
                        badCnt++
                    }
                }

                lastLine = $0
            }
        }
        END {
            printf("Bad count: %d\n", badCnt)
        }' < $f
done
}

WORKDIR=./

if [ "$1" != "" ]; then
    WORKDIR="$1"
fi

pushd "$WORKDIR"
    checkAttrNull
popd
