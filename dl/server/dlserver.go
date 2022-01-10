package main

import (
	"bytes"
	"context"
	"dl"
	"fmt"
	"github.com/apache/thrift/lib/go/thrift"
	"net/http"
	"os/exec"
)

func NewDownloadHandler() *dlserver {
	return &dlserver{}
}

type dlserver struct{}

var g_dlist []dl.Dlinfo

// Parameters:
//  - URL
//  - Filename
var g_NextDid int32 = 0

func (s *dlserver) AddDl(ctx context.Context, url string, filename string) (r int32, err error) {
	fmt.Printf("Add dl, next did: %d\n", g_NextDid)
	fmt.Println("Add download, url:", url, "filename: ", filename)
	g_NextDid++
	dlinfo := dl.Dlinfo{Did: g_NextDid, URL: url, Filename: filename}
	g_dlist = append(g_dlist, dlinfo)
	go dlfile(ctx, url, filename)
	return g_NextDid, nil
}

// Parameters:
//  - Did
func (s *dlserver) DelDl(ctx context.Context, did int32) (r int32, err error) {
	fmt.Printf("Delete download, did: %d\n", did)
	if did < g_NextDid {
		return 0, nil
	} else {
		return 1, nil
	}
}

// Parameters:
//  - Did
func (s *dlserver) PauseDl(ctx context.Context, did int32) (r int32, err error) {
	fmt.Printf("Pause download, did: %d\n", did)
	return 0, nil
}

// Parameters:
//  - Did
func (s *dlserver) ResumeDl(ctx context.Context, did int32) (r int32, err error) {
	fmt.Printf("Resume download, did:", did)
	return 0, nil
}

// Parameters:
//  - Maxcount
func (s *dlserver) GetDlList(ctx context.Context, maxcount int32) (r []*dl.Dlinfo, err error) {
	var i int32
	for i = 1; i < maxcount; i++ {
		r = append(r, &dl.Dlinfo{
			Did:      i,
			Filename: "file" + string(i),
			URL:      "http://file" + string(i),
			State:    4,
		})
	}

	return r, nil
}

// Parameters:
//  - Did
func (s *dlserver) Redown(ctx context.Context, did int32) (r int32, err error) {
	dlinfo := getDlInfo(did)
	fmt.Println("re downloading ", dlinfo.Filename)
	dlfile(ctx, dlinfo.URL, dlinfo.Filename)
	return 0, nil
}

// Parameters:
//  - Did
//  - Mindelta
func (s *dlserver) GetProgress(ctx context.Context, did int32, mindelta int32) (r int32, err error) {
	dlinfo := getDlInfo(did)
	return dlinfo.Progress, nil
}

func getDlInfo(did int32) *dl.Dlinfo {
	r := &dl.Dlinfo{Did: 100, Filename: "file100"}
	return r
}

func dlfile(ctx context.Context, url string, name string) (err error) {
	var cmd string

	if name != "" {
		cmd = "wget -O " + root + "/" + name + " " + url
	} else {
		cmd = "wget " + url
	}

	_, err = exec.CommandContext(ctx, "bash", "-c", cmd).Output()
	return err
}

type HTTPServerTransport struct {
	resp http.ResponseWriter
	req  *http.Request
	wbuf bytes.Buffer //write buffer
	rbuf bytes.Buffer //read buffer
}

func RunThriftInHTTPServer(w http.ResponseWriter, r *http.Request) {
	handler := NewDownloadHandler()
	processor := dl.NewDownloadProcessor(handler)

	transport := NewHTTPServerTransport(w, r)
	inProtocol := thrift.NewTJSONProtocol(transport)
	outProtocol := thrift.NewTJSONProtocol(transport)

	fmt.Println("Before process")
	ok, _ := processor.Process(context.Background(), inProtocol, outProtocol)
	if !ok {
		w.Write([]byte("Failed to process"))
	}
	fmt.Println("After process")
}

func NewHTTPServerTransport(w http.ResponseWriter, r *http.Request) *HTTPServerTransport {
	trans := HTTPServerTransport{resp: w, req: r}
	_, err := trans.rbuf.ReadFrom(r.Body)
	if err != nil {
		fmt.Println("Failed to read request data:", err)
	}

	return &trans
}

func (hst *HTTPServerTransport) Read(p []byte) (n int, err error) {
	a, b := hst.rbuf.Read(p)
	return a, b
}

func (hst *HTTPServerTransport) Write(p []byte) (n int, err error) {
	return hst.wbuf.Write(p)
}

func (hst *HTTPServerTransport) Close() error {
	return nil
}

func (hst *HTTPServerTransport) Flush(ctx context.Context) error {
	_, err := hst.wbuf.WriteTo(hst.resp)
	return err
}

func (hst *HTTPServerTransport) RemainingBytes() (num_bytes uint64) {
	leftBytes := hst.rbuf.Len()
	return uint64(leftBytes)
}

func (hst *HTTPServerTransport) Open() error {
	return nil
}

func (hst *HTTPServerTransport) IsOpen() bool {
	return true
}
