#!/usr/bin/env bash

source scripts/common.sh

service_name="prometheus"

sendLog "Start to create $service_name/docker-compose-production.yml ..." 1 g

# 检查必要的文件
compose_file="./docker/${service_name}/docker-compose.yaml"
conf1="./docker/${service_name}/conf/prometheus.yml.template"
checkFileForce "${conf1}"
checkFileForce "${compose_file}"
# 读取文件
docker_compose_production=$(<${compose_file})
prometheus_yaml=$(<${conf1})
# 替换变量
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "IMAGE" "image")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "TIME" "time")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "SIZE" "size")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "CPU" "cpu")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "MEMORY" "memory")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "NAME" "name")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "PORT" "port")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "network" "NETWORK_NAME" "network_name")
prometheus_yaml=$(replaceDockerConfig "${prometheus_yaml}" "${service_name}" "PORT" "port")

# 存储类创建
mkdir -p ./docker/${service_name}/data && chmod 777 ./docker/${service_name}/data

# 写入数据
echo "${docker_compose_production}" >./docker/${service_name}/docker-compose-production.yaml
echo "${prometheus_yaml}" >./docker/${service_name}/conf/prometheus.yml

# 生成启动文件
writeStart
writeStop
cp -rf start.sh stop.sh docker/${service_name}/

sendLog "Successfully created $service_name/docker-compose-production.yml !" 1 g