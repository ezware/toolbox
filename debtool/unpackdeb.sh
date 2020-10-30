#!/bin/bash

workdir=./
if [ $1 != "" ]; then
	workdir="$1"
fi

pushd "$workdir" >/dev/null
  files=$(ls -1 *.deb)

  for f in $files
  do
	todir=${f%.*}
	if [ -d "$todir" ]; then
		continue
	fi
	echo "Extracting $f to $todir"
	mkdir -p "${todir}/DEBIAN"
	dpkg -X "./$f" "$todir"
	dpkg -e "./$f" "${todir}/DEBIAN"
  done
popd 
