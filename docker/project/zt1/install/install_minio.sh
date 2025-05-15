#!/usr/bin/env bash

source scripts/common.sh

service_name="minio"


sendLog "Start to create $service_name/docker-compose-production.yml ..." 1

# 检查必要的文件
compose_file="./artifact/${service_name}/docker-compose.yaml"
checkFileForce "${compose_file}"
# 读取文件
docker_compose_production=$(<${compose_file})
# 替换变量
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "IMAGE" "image")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "CPU" "cpu")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "MEMORY" "memory")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "NAME" "name")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "PORT" "port")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "PORT_CONSOLE" "port_console")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "network" "NETWORK_NAME" "network_name")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "global" "PREFIX" "prefix")
# ak sk
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "ACCESSKEY" "accessKey")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "SECRETKEY" "secretKey")

# 初始化桶
mkdir -p ./artifact/${service_name}/data/connector
mkdir -p ./artifact/${service_name}/data/base-platform
mkdir -p ./artifact/${service_name}/data/dcau

chmod 777 -R  ./artifact/${service_name}/data

# 写入数据
echo "${docker_compose_production}" >./artifact/${service_name}/docker-compose-production.yaml

# 生成启动文件
writeStart
writeStop
writeRestart
writeUpdate
cp -rf  start.sh stop.sh restart.sh update.sh artifact/${service_name}/

sendLog "Successfully created $service_name/docker-compose-production.yml !" 1 g
