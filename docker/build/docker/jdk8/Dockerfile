# 使用 Maven 镜像作为基础镜像
FROM maven:3.8.7-openjdk-18 AS build

# 设置工作目录
WORKDIR /app

# 克隆远程 Git 仓库
RUN git clone https://github.com/mizhidajiangyou/JavaTest.git

# 切换到 Java 项目目录
WORKDIR /app/JavaTest

# 构建 Java 项目并生成 JAR 文件
RUN mvn clean package

# 使用一个基础的 Java 8 镜像作为基础镜像
FROM mzdjy/visualization:alpine-jave8

WORKDIR /app/
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk add tzdata
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone


# 将生成的 JAR 文件复制到容器中
COPY --from=build /app/JavaTest/target/*.jar /app/app.jar

# 复制应用程序到容器中
COPY --from=build /app/JavaTest/src/main/resources/application.properties /app/application.properties

EXPOSE 27771

ENTRYPOINT ["sh","-c","java -jar  app.jar --spring.config.location=./application.properties "]


