package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/ezware/toolbox/dl/dlserver"

	"github.com/gin-gonic/gin"
)

var (
	root    string
	port    uint
	addr    string = ""
	cfgFile string
)

func init() {
	flag.UintVar(&port, "port", 8080, "port to serve on")
	flag.StringVar(&root, "root", "/home/ezware/www/d/files", "root dir to save file")
	flag.StringVar(&addr, "addr", "", "address to serve on, default is all addresses")
	flag.StringVar(&cfgFile, "c", "dlconfig.json", "Config file (json)")
}

func signalProc(dls *dlserver.DLServer) {
	var s os.Signal

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	s = <-c
	fmt.Println("Received signal", s)
	switch s {
	case os.Interrupt:
		dls.Save(cfgFile)
	}
	os.Exit(0)
}

func main() {
	flag.Parse()
	addrAndPort := fmt.Sprintf("%s:%d", addr, port)

	fmt.Println("root:", root)

	//excutable path
	d := filepath.Dir(os.Args[0])
	if !filepath.IsAbs(cfgFile) {
		cfgFile = filepath.Join(d, cfgFile)
	} else {
		cfgdir := filepath.Dir(cfgFile)
		os.MkdirAll(cfgdir, 0764)
	}

	r := gin.Default()

	api := r.Group("api")
	dls := dlserver.NewDownloadServer(filepath.Join(root, "files"))
	dls.InitRoute(api)
	dls.LoadCfg(cfgFile)

	go signalProc(dls)

	r.NoRoute(func(c *gin.Context) {
		// 排除 /api
		hasAPIPrefix := strings.HasPrefix(c.Request.URL.Path, "/api/")
		fmt.Println("Path: ", c.Request.URL.Path, "has API prefix: ", hasAPIPrefix)
		reqpath := c.Request.URL.Path
		if reqpath != "/api" || !strings.HasPrefix(c.Request.URL.Path, "/api/") {
			// 服务静态文件
			if reqpath == "/" {
				reqpath = "/index.html"
			}
			serveFile := filepath.Join(root, reqpath)
			fmt.Println("Not API, serve static file: ", serveFile)
			http.ServeFile(c.Writer, c.Request, serveFile)
			return
		} else {
			fmt.Println("API, not serve static file")
		}

		// 如果路径是 /api 开头，但 dlserver 没有处理它（比如 /api/notfound），则返回 404
		c.AbortWithStatus(http.StatusNotFound)
	})

	err := r.Run(addrAndPort)
	if err != nil {
		fmt.Println(err)
	}
}
