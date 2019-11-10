package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"net/http"
	"os"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var (
	startblid  int
	endblid    int
	startbqcid int
	endbqcid   int
	mode       int
	maxbkcnt   int
)

const (
	CRMODE_BLID = iota
	CRMODE_BQCID
)

func init() {
	flag.IntVar(&startblid, "bid", 10766, "begin blid")
	flag.IntVar(&endblid, "eid", 10767, "end BLID")
	flag.IntVar(&startbqcid, "bqcid", 0, "begin bqcid")
	flag.IntVar(&endbqcid, "eqcid", 0, "end bqcid")
	flag.IntVar(&mode, "m", CRMODE_BLID, "search mode:\n\t0 BLID mode\n\t1 BQCID mode")
	flag.IntVar(&maxbkcnt, "bc", 1, "book count")
}

/*
资源列表 7094-11379
http://www.ecustpress.cn/ashx/qrList.ashx?blid=10766

referer
http://www.ecustpress.cn/erweima/player.html?bqc_id=23020(从上面列表获取data.list[0].listBookQrCode[i].bqc_id)

资源获取
http://hldqrcode1.oss-cn-shanghai.aliyuncs.com/wapaudio/41911(从model.blNo获取)/1.mp3(data.list[0].listBookQrCode[i].bqc_no)
*/
func main() {
	flag.Parse()

	var c *http.Client
	var url string
	var urlPrefix string = "http://hldqrcode1.oss-cn-shanghai.aliyuncs.com/wapaudio"
	var refPrefix string = "http://www.ecustpress.cn/erweima/player.html?bqc_id="
	var req *http.Request
	var resp *http.Response
	var err error
	var fn string
	var delay int
	var td time.Duration
	var bookInfo = map[string]interface{}{}
	var jsonBuf []byte
	var readBuf []byte = make([]byte, 4096)
	var jsonFileName string
	//var bkcnt int
	//var bqc_id int

	//var startblid = 10766
	//var endblid = 11380
	//var endblid = 10767

	rndSrc := rand.NewSource(time.Now().UnixNano())
	rnd := rand.New(rndSrc)

	reg := regexp.MustCompile(`[/:\*?\"><| ]`)

	//bqcmode:
	//bqc_id = startbqcid
	//for bkcnt = 0; bkcnt < maxbkcnt; bkcnt++ {
	//	jsonSrc := "http://www.ecustpress.cn/ashx/qrList.ashx?bqc_id=" + strconv.Itoa(bqc_id)
	//blmode:
	for blid := startblid; blid <= endblid; blid++ {
		jsonSrc := "http://www.ecustpress.cn/ashx/qrList.ashx?blid=" + strconv.Itoa(blid)
		resp, err = http.Get(jsonSrc)

		jsonBuf = jsonBuf[0:0]
		for {
			n, _ := resp.Body.Read(readBuf)
			if n > 0 {
				jsonBuf = append(jsonBuf, readBuf[0:n]...)
			} else {
				break
			}
		}

		jsonFileName = "last.json"
		ioutil.WriteFile(jsonFileName, jsonBuf, 0755)

		err = json.Unmarshal(jsonBuf, &bookInfo)
		if err != nil {
			fmt.Println("Failed to parse metadata.", err)
			continue
		}
		metaCode := map[string]interface{}(bookInfo)["code"]
		if metaCode.(float64) != 0 {
			fmt.Printf("%v.Failed to get data. %s\n", blid, jsonBuf)
			continue
		}

		bookData := map[string]interface{}(bookInfo)["data"]
		dtype := reflect.TypeOf(bookData).String()
		if dtype != "map[string]interface {}" {
			fmt.Println("%v.Type:", blid, dtype)
			continue
		}

		bookInfoList := bookData.(map[string]interface{})["list"]
		bookModel := bookData.(map[string]interface{})["model"]
		blNo := bookModel.(map[string]interface{})["blNo"].(string)
		blName := bookModel.(map[string]interface{})["blName"].(string)
		blNoParts := strings.Split(blNo, "-")
		blNo2 := strings.Join(blNoParts[3:], "")

		bookInfoList2 := bookInfoList.([]interface{})
		if len(bookInfoList2) < 1 {
			fmt.Println(blid, blName, "no resource list")
			continue
		}

		bookQrList := bookInfoList.([]interface{})[0].(map[string]interface{})["listBookQrCode"]

		fmt.Println("Getting", blid, blName)
		//fmt.Println("Getting bqc", bqc_id, blName)
		//blName 目录合法化, 正则替换
		blName = reg.ReplaceAllString(blName, "_")
		fmt.Println("GoodName:", blName)
		err = os.Mkdir(blName, 0755)
		if err != nil && os.IsNotExist(err) {
			fmt.Println(err)
			return
		}

		jsonFileName = fmt.Sprintf("%s/%v.json", blName, blid)
		ioutil.WriteFile(jsonFileName, jsonBuf, 0755)

		if endbqcid == 0 {
			endbqcid = len(bookQrList.([]interface{}))
		}
		for index, bookQr := range bookQrList.([]interface{}) {
			if index < startbqcid {
				continue
			}

			if index > endbqcid {
				break
			}

			bookQrContent := bookQr.(map[string]interface{})
			bqcid := bookQrContent["bqc_id"]
			bqcno := bookQrContent["bqc_no"]
			bqcname := bookQrContent["bqc_name"]
			bqctype := bookQrContent["bqc_type"]

			fn = fmt.Sprintf("%s/%v.%s.%s", blName, bqcno, bqcname, bqctype)
			url = fmt.Sprintf("%s/%s/%v.%s", urlPrefix, blNo2, bqcno, bqctype)
			ref := fmt.Sprintf("%s%v", refPrefix, bqcid)
			fmt.Printf("GET %s\nREF %s\n", url, ref)

			req, err = http.NewRequest("GET", url, nil)
			req.Header.Set("Referer", ref)
			req.Header.Set("Range", "bytes=0-")
			req.Header.Set("Accept-Encoding", "identity;q=1, *;q=0")
			req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3239.132 Safari/537.36")
			c = &http.Client{}
			resp, err = c.Do(req)
			//fmt.Println(req, err, resp, fn)
			downFile(resp, fn)
			delay = rnd.Intn(10)
			td = time.Duration(delay) * time.Second
			fmt.Println("Waiting for", td, "(", delay, ")", "seconds")
			time.Sleep(td)
		}
		endbqcid = 0
		//bqc_id++
	}

	return
}

func downFile(resp *http.Response, filename string) error {
	var fileLen int64
	raw := resp.Body
	defer raw.Close()
	reader := bufio.NewReaderSize(raw, 1024*32)
	file, err := os.Create(filename)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	defer writer.Flush()

	fmt.Printf("Saving to %s", filename)
	buff := make([]byte, 32*1024)
	written := 0
	for {
		nr, er := reader.Read(buff)
		if nr > 0 {
			fileLen = fileLen + int64(nr)
			nw, ew := writer.Write(buff[0:nr])
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

	fmt.Printf(", %v\n", fileLen)

	return nil
}
