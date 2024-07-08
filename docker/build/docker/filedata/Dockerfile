FROM alpine:3.20.1
RUN apk add --no-cache rsync

MAINTAINER "Open Platform"

USER root
COPY init_filedata.sh /init_filedata.sh
COPY data.tar.gz /data.tar.gz

WORKDIR /
ENTRYPOINT ["/init_filedata.sh"]
