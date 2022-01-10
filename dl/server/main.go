package main

import (
	"flag"
	"fmt"
	"net/http"
	//"github.com/apache/thrift/lib/go/thrift"
)

var (
	root string
	port uint
	addr string = ""
)

func init() {
	flag.StringVar(&root, "root", "/home/ezware/www/d/files", "root dir to save file")
	flag.UintVar(&port, "port", 8080, "port to serve on")
}

func main() {
	flag.Parse()
	addr = fmt.Sprintf("%s:%d", addr, port)

	mux := http.NewServeMux()
	//mux.HandleFunc("/", fileHandler)
	//mux.HandleFunc("/upload", upload)
	//mux.HandleFunc("/download", download)
	mux.HandleFunc("/thrift", thriftReqHandler)
	//mux.HandleFunc("/pty", startWebpty)
	//mux.HandleFunc("/execBash",execBash)

	err := http.ListenAndServe(addr, mux)
	fmt.Println(err)
}

func thriftReqHandler(w http.ResponseWriter, r *http.Request) {
	hdr := w.Header()
	hdr.Add(string("Access-Control-Allow-Origin"), string("*"))
	hdr.Add(string("Access-Control-Allow-Methods"), string("POST, GET, OPTIONS, DELETE"))
	hdr.Add(string("Access-Control-Allow-Headers"), string("content-type"))
	RunThriftInHTTPServer(w, r)
}
