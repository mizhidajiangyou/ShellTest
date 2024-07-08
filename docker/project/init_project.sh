#!/usr/bin/env bash
# 该脚本用于根据配置文件来初始化project中需要的compose和install安装脚本。
# e.g. ./init_project.sh

#set -xeo pipefail
# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function initCFG() {
  if [ ! -f global.cfg ]; then
    sendLog "write global.cfg" 0
    cat >global.cfg <<EOF
等待添加
EOF
  fi
  if [ ! -f images.cfg ]; then
    sendLog "write images.cfg" 0
    cat >images.cfg <<EOF
等待添加
EOF
  fi
}

function initInstall() {
  local service_name="$1"
  sendLog "Start to create install_${service_name}.sh ..." 1
  cat >install_"${service_name}".sh <<EOF
#!/usr/bin/env bash

source scripts/common.sh

service_name="${service_name}"

EOF

  cat >>install_"${service_name}".sh <<'EOF'

sendLog "Start to create $service_name/docker-compose-production.yml ..." 1

# 检查必要的文件
compose_file="./docker/${service_name}/docker-compose.yaml"
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
mkdir -p ./docker/${service_name}/data && chmod 777 ./docker/${service_name}/data

# 写入数据
echo "${docker_compose_production}" >./docker/${service_name}/docker-compose-production.yaml

# 生成启动文件
writeStart
writeStop
writeRestart
writeUpdate
cp -rf  start.sh stop.sh restart.sh update.sh docker/${service_name}/

sendLog "Successfully created $service_name/docker-compose-production.yml !" 1 g
EOF
}

function initDocker() {
  cat >docker-compose.yaml <<'EOF'
version: '3.8'
services:
  {{ NAME }}:
    image: {{ IMAGE }}
    deploy:
      resources:
        limits:
          cpus: "{{ CPU }}"
          memory: "{{ MEMORY }}"
    restart: always
    container_name: {{ NAME }}
    environment:
      - TZ=Asia/Shanghai
    labels:
      mz-app.platform: "mz"
      mz-app.type: "system"
      mz-app.service: "mz-"
      mz-app.metric: "{{ PORT }}"
    hostname: {{ NAME }}
    volumes:
      - ./data:/home/data
    ports:
      - "{{ PORT }}:3000/tcp"
    logging:
      driver: "json-file"
      options:
        max-size: "5M"
        max-file: "10"
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:3000/-/healthy || exit 1
      interval: 10s
      retries: 5
      timeout: 10s
      start_period: 10s
    networks:
      - network1
networks:
  network1:
    external: true
    name: {{ NETWORK_NAME }}
EOF
}

function main() {
  # 判断项目名称对应的目录是否存在
  if [ ! -d "$project_name" ]; then
    # 如果不存在则创建目录
    mkdir -p "$project_name"
  fi

  # 进入项目名称对应的目录
  cd "$project_name" || exit 1
  mkdir -p install docker
  # 循环读取组件列表
  for component in "${components[@]}"; do
    pushd install &> "${LOG_FILE}"|| exit 1
    sendLog "create install_${component} ..." 1
    initInstall "$component"
    popd &> "${LOG_FILE}"|| exit 1
    pushd docker &> "${LOG_FILE}"|| exit 1
    # 判断目录组件是否存在
    if [ ! -d "$component" ]; then
      mkdir -p "$component"
      pushd "$component"  &> "${LOG_FILE}" || exit 1
      sendLog "create $component/docker-compose.yaml ..." 1
      initDocker "$component"
      popd &> "${LOG_FILE}"|| exit 1
    else
      sendLog "Docker $component already exists, skipping..." 2
    fi
    popd &> "${LOG_FILE}"|| exit 1
  done

  # 输出完成
  sendLog "All components initialized successfully." 1 g
}

# 检查参数个数是否大于等于2
if [ "$#" -lt 2 ]; then
  # 如果小于2则报错并结束脚本
  sendLog "Usage: $0 <project_name> <component1> [component2] ..." 3
  exit 1
fi
project_name=$1
shift
components=("$@")

main
