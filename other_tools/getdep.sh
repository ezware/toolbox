#!/bin/bash

# get dependencies of an executable
[ $# -eq 0 ] && echo "usage: $0 executable_file [ depdir ]" && exit 1

p=$1
p=$(which $p)
depdir=./dep
if [ "$2" != "" ]; then
        depdir="$2"
fi
mkdir -p "$depdir"
maxcall=10000
i=0

function copylib()
{
        if [ ! -e "$depdir/$1" ]; then
                cp --parents $1 "$depdir"
        fi
}

function getdep()
{
        local libs
        local libs2
        libs=$(ldd "$1" | grep = | awk '{print $3}')

        ((i++))
        if ((i > maxcall)); then
                echo "Max call reached!"
                return
        fi

        for lib in $libs
        do
                copylib "$lib"
        done

        for lib in $libs
        do
                libs2=$(ldd "$lib" | grep = | awk '{print $3}')
                for lib2 in $libs2
                do
                        if [ ! -e "$depdir/$lib2" ]; then
                                copylib "$libs2"
                                getdep "$lib2"
                        fi
                done
        done
}

copylib "$p"
getdep "$p"
