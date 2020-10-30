package main

import (
	"flag"
	"fmt"
	"net/http"

	"github.com/AaronO/go-git-http"
)

/*
type httpWrapper struct {
    gitHttpHandler http.Handler
}

func (wrapper *httpWrapper) ServeHTTP (resp http.ResponseWriter, req *http.Request) {
    //add .git if needed
    fmt.Println(req.URL.Path)

    //call the git handler
    wrapper.gitHttpHandler(resp, req)
}
*/

var (
	rootdir  string
	httpport int
)

func init() {
	flag.StringVar(&rootdir, "root", "/www/gitmirror", "specify the git repo root")
	flag.IntVar(&httpport, "port", 8000, "specify the http listen port")
}

func main() {
	flag.Parse()
	// Get git handler to serve a directory of repos
	git := githttp.New(rootdir)

	/*
	   var githack = httpWrapper{}
	   githack.gitHttpHandler = git
	*/

	// Attach handler to http server
	http.Handle("/", git)

	// Start HTTP server
	listenAddr := fmt.Sprintf(":%d", httpport)
	err := http.ListenAndServe(listenAddr, nil)
	if err != nil {
		fmt.Println("ListenAndServe: ", err)
	}

	return
}
