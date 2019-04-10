package main

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"os"
)

func main() {
	d := md5.New()
	blksz := d.BlockSize()

	var n int = 0
	var b []byte = make([]byte, blksz)
	var s []byte

	//fmt.Printf("BlockSize: %d\nFiles: %v\n", blksz, os.Args[1:])
	for _, fn := range os.Args[1:] {
		fmt.Printf("%v\n", fn)
		f, err := os.Open(fn)
		if err != nil {
			fmt.Printf("  error: %v\n", err)
		} else {
			d.Reset()
			n = 1
			for n > 0 {
				n, err = f.Read(b)
				if err != nil {
					break
				}
				d.Write(b[0:n])
			}
			s = d.Sum(nil)
			f.Close()
			fmt.Printf("  %v\n", hex.EncodeToString(s))
		}
	}

	os.Stdin.Read(b[:1])
}
