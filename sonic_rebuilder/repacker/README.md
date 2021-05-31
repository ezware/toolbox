# Usage
## get fs.zip
```
#extract
sed -e '1,/^exit_marker$/d' sonic-broadcom.bin | tar -xf -

#fs.zip is under installer dir
ls installer/fs.zip
```

## repack
drop the fs.zip to this folder and run ./repack.sh
