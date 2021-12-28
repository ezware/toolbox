#############################
# Download Service Makefile #
#############################

svr:
	@echo "Building server"
	make -C server

thriftgen:
	make -C thrift

cl:
	@echo "TODO: build client"

all: thriftgen svr cl
	@echo "Done"

clean:
	make -C thrift clean
	rm -rf server/server
	rm -rf client/xxx
