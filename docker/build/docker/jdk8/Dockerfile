# 使用一个基础的 Java 8 镜像作为基础镜像
FROM mzdjy/visualization:alpine-jave8

WORKDIR /data/app/
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk add tzdata
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone


COPY ./config /data/app/config

COPY ./application-test.yml /data/app

COPY ./test.jar /data/app


EXPOSE 27771

ENTRYPOINT ["sh","-c","java ${JAVA_OPTS} -Xms500m -Xmx500m -Xmn125m -XX:+UseG1GC  test.jar --spring.config.location=./application-test.yml"]


