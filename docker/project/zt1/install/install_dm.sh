#!/usr/bin/env bash

source scripts/common.sh

service_name="dm"
# 该服务需要把预置的内容拷出来
mkdir -p ./data && chmod 755 data
# 获取镜像
docker_conf_image=$(configParser "${service_name}" "image" "images.cfg")
sendLog "From ${docker_conf_image} to cp config." 1
# 启动docker
runDocker  "${service_name}" "${docker_conf_image}"
# 拷贝
cpDocker "${service_name}:/opt/dmdbms/data" "./data"
# 停用docker
stopDocker  "${service_name}"
# 确认是否存活
if ! checkDockerExist "${service_name}" ; then
  sendLog "Do checkDockerExist Failed ! Please docker ps -a to check it !" 3
  exit 1
fi

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
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "network" "NETWORK_NAME" "network_name")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "global" "PREFIX" "prefix")
# 存储类创建
mkdir -p ./artifact/${service_name}/data && chmod 777 ./artifact/${service_name}/data

# 写入数据
echo "${docker_compose_production}" >./artifact/${service_name}/docker-compose-production.yaml

# 生成启动文件
writeStart
writeStop
writeRestart
writeUpdate
cp -rf  start.sh stop.sh restart.sh update.sh artifact/${service_name}/

sendLog "Successfully created $service_name/docker-compose-production.yml !" 1 g
