#!/bin/bash
# split the file content into multiple files
# e.g. split a lt command output into multi files, put each entry in a file.

# source file name
fn=$1

awk -v bfn="$fn" 'BEGIN {
	fid=1; fn=sprintf("%s.%03d.txt", bfn, fid)
	print "" >fn
}
{
    #split condition
    # if ($0 ~ /^$/)
	if ($0 ~ /^[A-Z]/) {
		fid++;
		fn=sprintf("%s.%03d.txt", bfn, fid)
		print $0 > fn
	}
	else
	{
		print $0 >> fn	
	}
}
' < "$fn"
