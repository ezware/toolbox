FROM scratch

ADD bin /bin
ADD lib /lib
ADD lib64 /lib64
ADD scripts /scripts
RUN addlink.sh

ENTRYPOINT [ "/bin/githttp" ]
