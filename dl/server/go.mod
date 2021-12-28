module dl/server

go 1.16

require github.com/apache/thrift v0.13.0

require dl v0.0.0

replace dl => ../thrift/gen-go/dl
