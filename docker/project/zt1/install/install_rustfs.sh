#!/usr/bin/env bash

source scripts/common.sh

service_name=$(get_install_name "$0")


sendLog "Start to create $service_name/docker-compose-production.yml ..." 1

# 检查必要的文件
compose_file="./artifact/${service_name}/docker-compose.yaml"
checkFileForce "${compose_file}"
# 读取文件
docker_compose_production=$(<${compose_file})
# 替换通用变量
docker_compose_production=$(config_common "${docker_compose_production}" "${service_name}")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "PORT_CONSOLE" "port_console")
# ak sk
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "ACCESSKEY" "accessKey")
docker_compose_production=$(replaceDockerConfig "${docker_compose_production}" "${service_name}" "SECRETKEY" "secretKey")

# 初始化桶
mkdir -p ./artifact/"${service_name}"/data/test
chown -R 10001:10001 ./artifact/"${service_name}"/data/test

chmod 777 -R  ./artifact/"${service_name}"/data

# 写入数据
echo "${docker_compose_production}" >./artifact/"${service_name}"/docker-compose-production.yaml

# 生成启动文件
writeUsefulSH "artifact/${service_name}"

sendLog "Successfully created $service_name/docker-compose-production.yml !" 1 g
