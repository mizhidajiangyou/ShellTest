#!/usr/bin/env bash

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function writeStart() {
  if [ ! -f start.sh ]; then
    sendLog "write start.sh" 0
    cat >start.sh <<EOF
#!/bin/bash

docker-compose -f docker-compose-production.yaml up -d
EOF
    chmod +x start.sh
  fi
}

function writeStop() {
  if [ ! -f stop.sh ]; then
    sendLog "write stop.sh" 0
    cat >stop.sh <<EOF
#!/bin/bash

docker-compose -f docker-compose-production.yaml down
EOF
    chmod +x stop.sh
  fi
}

function writeRestart() {
  if [ ! -f restart.sh ]; then
    sendLog "write restart.sh" 0
    cat >restart.sh <<EOF
#!/bin/bash

docker-compose -f docker-compose-production.yaml restart
EOF
    chmod +x restart.sh
  fi
}

function writeUpdate() {
  if [ ! -f update.sh ]; then
    sendLog "write update.sh" 0
    cat >update.sh <<EOF
#!/bin/bash

docker-compose -f docker-compose-production.yaml pull
docker-compose -f docker-compose-production.yaml restart
EOF
    chmod +x update.sh
  fi
}

function checkFileForce() {
  local file=$1
  if [ ! -f "${file}" ]; then
    sendLog "${file} does not exist!" 3
    exit 1
  fi
}

function getSwitch() {
  configParser "multi" "switch" "images.cfg"
}

function getPath() {
  configParser "storage" "install_path" "images.cfg"
}

function replaceDockerConfig() {
  # 被替换的字符串
  local string=$1
  # 服务
  local service_name=$2
  # 匹配源
  local aboriginal=$3
  # 匹配值
  local replaced=$4
  local value
  value="$(configParser "${service_name}" "${replaced}" images.cfg)"
  # 特殊处理cpu、内存、名称
  if [ "${replaced}" == "cpu" ] || [ "${replaced}" == "memory" ]; then
    local quota
    quota=$(configParser "global" "quota" "images.cfg")
    value=$(echo "$value" | awk '{ sub("M", ""); sub("G", ""); printf "%.2f", $1 * '"$quota"' }')
    if [ "${replaced}" == "memory" ]; then
      value="${value}M"
    fi
  elif [ "${replaced}" == "name" ] || [ "${replaced}" == "exporter_name" ]; then
    local prefix
    prefix=$(configParser "global" "prefix" "images.cfg")
    value="${prefix}-${value}"
  fi
  replaceCompose "${string}" "${aboriginal}" "${value}"
}

function for_service_do() {
  local service_list ser function_name function_args
  function_name=$1
  shift
  function_args=$*
  service_list=$(configParser install service images.cfg)
  # shellcheck disable=SC2034
  for ser in ${service_list[*]}; do
    "$function_name" "$ser" "$function_args"
  done
}

function runDocker() {
  local name=$1
  local image=$2
  docker run --rm -itd --entrypoint /bin/sh --name "${name}" "${image}" -c "tail -f /dev/null"
}

function stopDocker() {
  docker stop "$1"
}

function cpDocker() {
  local source=$1
  local destination=$2
  docker cp "${source}" "${destination}"
}

function checkDockerExist() {
  if docker ps -a | grep -q "$1"; then
    sendLog "docker $1 is running" 3 &> /dev/null
    return 1
  else
    return 0
  fi
}
