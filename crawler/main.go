package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"math/rand"
	//"strconv"
	"strings"
	"time"
)
/*
资源列表
http://www.ecustpress.cn/ashx/qrList.ashx?blid=10766

referer
http://www.ecustpress.cn/erweima/player.html?bqc_id=23020(从上面列表获取data.list[0].listBookQrCode[i].bqc_id)

资源获取
http://hldqrcode1.oss-cn-shanghai.aliyuncs.com/wapaudio/41911(从model.blNo获取)/1.mp3(data.list[0].listBookQrCode[i].bqc_no)
*/
func main() {
	fmt.Println("aaa")

	var c *http.Client
	var url string
	var ref string = "http://www.ecustpress.cn/erweima/player.html?bqc_id=23020"
	var req *http.Request
	var resp *http.Response
	var err error
	var strbuilder strings.Builder
	var fn string
	var delay int
	var td time.Duration

	rndSrc := rand.NewSource(time.Now().UnixNano())
	rnd := rand.New(rndSrc)

	for i := 1; i < 3; i++ {
		//i := 1
		strbuilder.Reset()
		strbuilder.WriteString("http://hldqrcode1.oss-cn-shanghai.aliyuncs.com/wapaudio/41911/")
		//strconv.Itoa(i) + ".mp3"
		fn = fmt.Sprintf("%02d.mp3", i)
		strbuilder.WriteString(fn)
		url = strbuilder.String()
		fmt.Println(url)
		req, err = http.NewRequest("GET", url, nil)
		req.Header.Set("Referer", ref)
		req.Header.Set("Range", "bytes=0-")
		req.Header.Set("Accept-Encoding", "identity;q=1, *;q=0")
		req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36");
		c = &http.Client{}
		resp, err = c.Do(req)
		fmt.Println(req, err, resp, fn)
		downFile(resp, fn)
		delay = rnd.Intn(30)
		td = time.Duration(delay) * time.Second
		fmt.Println("Waiting for", td, "(", delay, ")", "seconds")
		time.Sleep(td)
	}
	//Request URL:http://hldqrcode1.oss-cn-shanghai.aliyuncs.com/wapaudio/41911/17.mp3
	//Request Method:GET

	return
}

func downFile(resp *http.Response, filename string) error {
	raw := resp.Body
	defer raw.Close()
	reader := bufio.NewReaderSize(raw, 1024*32)
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	defer writer.Flush()

	buff := make([]byte, 32*1024)
	written := 0
	for {
		fmt.Println("Written:", written)
		nr, er := reader.Read(buff)
		if nr > 0 {
			fmt.Println(nr)
			nw, ew := writer.Write(buff[0:nr])
			//fmt.Println(string(buff[0:nr]))
			if nw > 0 {
				written += nw
			}
			if ew != nil {
				err = ew
				break
			}
			if nr != nw {
				err = io.ErrShortWrite
				break
			}
		} else {
			fmt.Println(nr, er)
		}

		if er != nil {
			if er != io.EOF {
				err = er
			}
			break
		}
	}

	return nil
}
