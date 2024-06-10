package dlserver

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	"os/exec"

	"github.com/gin-gonic/gin"
	"nhooyr.io/websocket"
)

func NewDownloadServer(fileroot string) *DLServer {
	return &DLServer{
		fileroot: fileroot,
	}
}

type DLServer struct {
	dlList   []*DLInfo
	nextDid  int
	fileroot string
}

type DLState int

const (
	DL_STATE_INIT DLState = iota
	DL_STATE_DOWNLOADING
	DL_STATE_PAUSED
	DL_STATE_COMPELETED
)

type DLInfo struct {
	Did      int     `json:"did" db:"did"`
	Filename string  `json:"filename" db:"filename"`
	URL      string  `json:"url" db:"url"`
	State    DLState `json:"-" db:"state"`
	StateStr string  `json:"state" db:"-"`
	Size     int64   `json:"size" db:"size"`
	Progress int     `json:"progress" db:"progress"`
	Location *string `json:"location,omitempty" db:"location" `
}

func (s *DLServer) InitRoute(api *gin.RouterGroup) {
	api.POST("dl", s.AddDl)
	api.GET("dl", s.ListDl)
	api.GET("dl/:id", s.GetDl)
	api.POST("dl/:id/pause", s.PauseDl)
	api.POST("dl/:id/resume", s.ResumeDl)
	api.DELETE("dl/:id", s.DelDl)
	api.GET("ws", wsHandler)
}

type AddDlReq struct {
	URL      string `json:"url" form:"url"`
	FileName string `json:"fileName" form:"fileName"`
}

func toStateStr(state DLState) string {
	switch state {
	case DL_STATE_INIT:
		return "init"
	case DL_STATE_DOWNLOADING:
		return "downloading"
	case DL_STATE_PAUSED:
		return "paused"
	case DL_STATE_COMPELETED:
		return "completed"
	}
	return "unknown"
}

func (s *DLServer) AddDl(ctx *gin.Context) {
	var req AddDlReq
	ctx.ShouldBindJSON(&req)
	url := req.URL
	filename := req.FileName
	fmt.Printf("Add dl, next did: %d\n", s.nextDid)
	fmt.Println("Add download, url:", url, "filename: ", filename)
	s.nextDid++
	dlInfo := &DLInfo{Did: s.nextDid, URL: url, Filename: filename, State: DL_STATE_INIT}
	dlInfo.StateStr = toStateStr(dlInfo.State)
	s.dlList = append(s.dlList, dlInfo)

	fileSizeUpdated := false

	go func() {
		size, err := getFileSize(url)
		if err != nil {
			fmt.Printf("Error getting file size, url: %s, err: %s\n", url, err)
		} else {
			if fileSizeUpdated {
				return
			}

			dlInfo.Size = size
		}
	}()

	go func() {
		if err := s.dlfile(url, filename); err != nil {
			fmt.Printf("Error downloading file: %s\n", err)
		} else {
			fmt.Printf("Download completed: %s, %s\n", url, filename)
			dlInfo.State = DL_STATE_COMPELETED
			dlInfo.StateStr = toStateStr(dlInfo.State)
			dlInfo.Progress = 100
			newsize, err := s.getFileSize(filename)
			if err != nil {
				fmt.Printf("Error getting file size, filename: %s, err: %s\n", filename, err)
			} else {
				fileSizeUpdated = true
				dlInfo.Size = newsize
			}
		}
	}()
	ctx.JSON(http.StatusOK, gin.H{"status": "Added", "did": s.nextDid})
}

// Parameters:
//   - Did
func (s *DLServer) DelDl(ctx *gin.Context) {
	//, did int32
	//(r int32, err error)
	var did int
	didstr := ctx.Param("did")
	n, err := fmt.Sscanf(didstr, "%d", &did)
	if err != nil || n != 1 {
		fmt.Printf("failed to parse did: %d, %s, %s\n", n, didstr, err)
		ctx.JSON(http.StatusOK, gin.H{"status": "failed to parse did", "did": didstr})
		return
	}
	fmt.Printf("Delete download, did: %d\n", did)
	for i, info := range s.dlList {
		if info.Did == did {
			s.dlList = append(s.dlList[:i], s.dlList[i+1:]...)
			ctx.JSON(http.StatusOK, gin.H{"status": "Deleted", "did": did})
			return
		}
	}
	ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Download not found"})
}

// Parameters:
//   - Did
func (s *DLServer) GetDl(ctx *gin.Context) {
	//, did int32
	//(r int32, err error)
	var did int
	didstr := ctx.Param("did")
	n, err := fmt.Sscanf(didstr, "%d", &did)
	if err != nil || n != 1 {
		ctx.JSON(http.StatusOK, gin.H{"status": "failed to parse did", "did": didstr})
		return
	}

	for _, info := range s.dlList {
		if info.Did == did {
			ctx.JSON(http.StatusOK, gin.H{"status": "Found", "dlinfo": info})
			return
		}
	}

	ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Download not found"})
}

// Parameters:
//   - Did
func (s *DLServer) PauseDl(ctx *gin.Context) {
	//, did int32  (r int32, err error)
	//fmt.Printf("Pause download, did: %d\n", did)
	//return //0, nil
}

// Parameters:
//   - Did
func (s *DLServer) ResumeDl(ctx *gin.Context) {
	//, did int32(r int32, err error)
	//fmt.Printf("Resume download, did:", did)
	//return //0, nil
}

type ListReq struct {
	MaxCount int `json:"maxCount,omitempty" form:"maxCount,omitempty" binding:"omitempty"`
}

// Parameters:
//   - Maxcount
func (s *DLServer) ListDl(ctx *gin.Context) {
	var req ListReq
	err := ctx.BindQuery(&req)
	if err != nil {
		fmt.Printf("failed to parse maxcount: %d, %s\n", req.MaxCount, err)
		ctx.JSON(http.StatusOK, gin.H{"status": "failed to parse maxcount", "maxcount": req.MaxCount})
		return
	}

	max := req.MaxCount
	if max == 0 {
		max = 100
	}
	lc := len(s.dlList)
	if lc < max {
		max = lc
	}

	if lc == 0 {
		ctx.JSON(http.StatusOK, gin.H{"status": "ok", "dllist": []DLInfo{}})
	} else {
		ctx.JSON(http.StatusOK, gin.H{"status": "ok", "dllist": s.dlList[:max]})
	}
}

func (s *DLServer) Redown(ctx *gin.Context) {
	var did int
	didstr := ctx.Param("did")
	n, err := fmt.Sscanf(didstr, "%d", &did)
	if err != nil || n != 1 {
		ctx.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "failed to parse did"})
		return
	}

	dlInfo := s.getDLInfo(did)
	if dlInfo == nil {
		ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	go func() {
		err = s.dlfile(dlInfo.URL, "")
		if err != nil {
			fmt.Printf("Error re-downloading file: %s\n", err)
		} else {
			fmt.Printf("Re-downloaded file: %d\n", did)
		}
	}()

	ctx.JSON(http.StatusOK, gin.H{"status": "Re-download started", "did": did})
}

func (s *DLServer) getDLInfo(did int) *DLInfo {
	for _, info := range s.dlList {
		if info.Did == did {
			return info
		}
	}
	return nil
}

func (s *DLServer) GetProgress(ctx *gin.Context) {
	// 从 ctx 中提取 did 参数
	var did int
	didstr := ctx.Param("did")
	n, err := fmt.Sscanf(didstr, "%d", &did)
	if err != nil || n != 1 {
		ctx.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "failed to parse did"})
		return
	}

	// 使用 s.getDLInfo 而不是独立的 getDLInfo 函数
	dlInfo := s.getDLInfo(did)
	if dlInfo == nil {
		ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	// 返回进度信息给客户端
	ctx.JSON(http.StatusOK, gin.H{"status": "ok", "progress": dlInfo.Progress})
}

func (s *DLServer) dlfile(url string, name string) (err error) {
	var cmd string

	if name != "" {
		cmd = "wget -O " + filepath.Join(s.fileroot, name) + " " + url
	} else {
		cmd = "wget " + url
	}

	data, err := exec.Command("bash", "-c", cmd).Output()
	if err != nil {
		fmt.Printf("failed to download file, cmd: %s, error: %s", cmd, err)
		return err
	}

	fmt.Println(string(data) + "\n")

	return err
}

func (s *DLServer) getFileSize(name string) (int64, error) {
	fullpath := filepath.Join(s.fileroot, name)
	finfo, err := os.Stat(fullpath)
	if err != nil {
		return 0, err
	}

	return finfo.Size(), nil
}

// DownloadFileWithResume 支持断点续传的文件下载函数
func DownloadFileWithResume(url string, filepath string) error {
	// 尝试打开文件以获取已下载的大小
	file, err := os.OpenFile(filepath, os.O_CREATE|os.O_RDWR|os.O_APPEND, 0666)
	if err != nil {
		return err
	}
	defer file.Close()

	// 获取已下载的文件大小
	fi, err := file.Stat()
	if err != nil {
		return err
	}
	startByte := fi.Size()

	// 发起带有 Range 头的 HTTP 请求
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	if startByte > 0 {
		req.Header.Set("Range", fmt.Sprintf("bytes=%d-", startByte))
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// 检查HTTP响应状态码
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusPartialContent {
		return fmt.Errorf("server returned non-200 status: %d", resp.StatusCode)
	}

	// 如果 Range 请求失败，并且服务器返回了完整的文件，则重置文件大小并从头开始下载
	if resp.StatusCode == http.StatusOK && startByte > 0 {
		_ = file.Truncate(0)
		startByte = 0
	}

	// 将响应体追加到文件中
	_, err = io.Copy(file, resp.Body)
	return err
}

func getFileSize(url string) (int64, error) {
	resp, err := http.Head(url)
	if err != nil {
		return 0, err
	}
	size, err := strconv.ParseInt(resp.Header.Get("Content-Length"), 10, 64)
	if err != nil {
		return 0, err
	}
	return size, nil
}

func wsHandler(c *gin.Context) {
	// 升级HTTP请求到WebSocket连接
	ws, err := websocket.Accept(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Error accepting WebSocket connection: %v", err)
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}
	defer ws.Close(websocket.StatusNormalClosure, "")

	// 处理WebSocket消息
	for {
		_, message, err := ws.Read(context.Background())
		if err != nil {
			log.Printf("Error reading WebSocket message: %v", err)
			break
		}
		log.Printf("Received message: %s", string(message))

		// 向客户端发送消息
		err = ws.Write(context.Background(), websocket.MessageText, []byte("Message received!"))
		if err != nil {
			log.Printf("Error sending WebSocket message: %v", err)
			break
		}
	}
}

func (s *DLServer) Save(cfgfile string) {
	dljson, err := json.Marshal(s.dlList)
	if err != nil {
		log.Println("Marshal dlList error:", err)
		return
	}
	err = os.WriteFile(cfgfile, dljson, 0644)
	if err != nil {
		log.Println("Save dlList error:", err)
	}
}

func (s *DLServer) LoadCfg(cfgfile string) {
	dljson, err := os.ReadFile(cfgfile)
	if err != nil {
		log.Println("Load dlList error:", err)
	} else {
		err = json.Unmarshal(dljson, &s.dlList)
		if err != nil {
			log.Println("Unmarshal dlList error:", err)
		}

		maxdid := 0
		for _, dl := range s.dlList {
			if maxdid < dl.Did {
				maxdid = dl.Did
			}
		}
		s.nextDid = maxdid
	}
}
