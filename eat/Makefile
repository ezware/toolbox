all: so

so:
	gcc -o eat eat.c

static:
	gcc -o eat -static eat.c

docker: static
	docker build -t eat :latest

rmdockerimg:
	docker rmi -f eat:latest

clean:
	rm -f eat eat_dy *.o
