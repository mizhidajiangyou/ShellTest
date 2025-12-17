#!/usr/bin/env bash

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function writeUsefulSH() {
    writeStart
    writeStop
    writeRestart
    writeUpdate
    writeLog
}

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

function writeLog() {
  if [ ! -f log.sh ]; then
    sendLog "write log.sh" 0
    cat >log.sh <<EOF
#!/bin/bash
DIR_NAME=$(basename "$PWD")


CONTAINER=$(docker ps --format "{{.Names}}" | grep "$DIR_NAME" | head -n 1)

if [ -z "$CONTAINER" ]; then
  echo "没有找到与目录名 $DIR_NAME 匹配的容器"
else
  docker logs --tail 100 -f "$CONTAINER"
fi
EOF
    chmod +x log.sh
  fi
}


function writeRestart() {
  if [ ! -f restart.sh ]; then
    sendLog "write restart.sh" 0
    cat >restart.sh <<EOF
#!/bin/bash

docker-compose -f docker-compose-production.yaml down
docker-compose -f docker-compose-production.yaml up -d
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
docker-compose -f docker-compose-production.yaml down
docker-compose -f docker-compose-production.yaml up -d
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
  if docker cp "${source}" "${destination}"; then
    sendLog " docker cp ${source} ${destination} successful" 1
  else
    sendLog " docker cp ${source} ${destination} failed,use docker ps and check it!" 3
    exit 1
  fi
}

function run_and_cp_from_docker() {
  local name=$1
  local image=$2
  local source=$3
  local destination=$4
  name="${name}-$(urandomStr 5)"
  runDocker "$name" "$image"
  cpDocker "$name:$source" "$destination"
  stopDocker "$name"

}

function checkDockerExist() {
  if docker ps -a | grep -q "$1"; then
    sendLog "docker $1 is running" 3 &>/dev/null
    return 1
  else
    return 0
  fi
}

function check_service_config() {
  local service_name=${1:-mysql}
  if [ ! -f ./artifact/"${service_name}"/.config_init ]; then
    sendLog "no such file:./artifact/${service_name}/.config_init ,start to copy from docker images."
    if ! ./scripts/conf.sh "${service_name}"; then
      sendLog "copy error!" 3
      return 1
    fi
    touch ./artifact/"${service_name}"/.config_init
    sendLog "copy fi"
  else
    sendLog "skip copy."
  fi

}

function get_install_name() {

  local input_str="$1"

  echo "$input_str" | awk '
    /.*\/install_(.*)\.sh$/ {
      sub(/.*install_/, "", $0)
      sub(/\.sh$/, "", $0)
      print $0
    }
  '

}
