package main

import (
	"flag"
	"fmt"
	"github.com/goproxy/goproxy"
	"net/http"
	"os"
)

var (
	rootdir  string
	httpport int
)

func init() {
	flag.StringVar(&rootdir, "gopath", "/www/goproxy", "specify the go path to store downloaded file")
	flag.IntVar(&httpport, "port", 8100, "specify the goproxy listen port")
}

func main() {
	flag.Parse()

	gopathEnv := "GOPATH=" + rootdir
	listenAddr := fmt.Sprintf(":%d", httpport)

	g := goproxy.Goproxy{}
	g.GoBinEnv = append(
		os.Environ(),
		"GOPROXY=https://goproxy.cn,direct", // Use goproxy.cn as the upstream proxy
		gopathEnv,
		//		"GOPRIVATE=git.example.com",         // Solve the problem of pulling private modules
	)
	g.ProxiedSUMDBs = []string{"sum.golang.org https://goproxy.cn/sumdb/sum.golang.org"} // Proxy the default checksum database

	fmt.Printf("Listenning on \"%s\", %s\n", listenAddr, gopathEnv)

	http.ListenAndServe(listenAddr, &g)
}
