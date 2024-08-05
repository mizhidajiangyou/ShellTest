FROM mzdjy/visualization:nginx-1.21.1

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

#set timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo 'Asia/Shanghai' >/etc/timezone

# 静态web文件
COPY dists .
# 默认nginx配置
COPY nginx.conf /etc/nginx/
# ng include文件
COPY conf.d /etc/nginx/conf.d/

