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

function checkFileForce() {
  local file=$1
  if [ ! -f "${file}" ]; then
    sendLog "${file} does not exist!" 3
    exit 1
  fi
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
  elif [ "${replaced}" == "name" ]; then
    local prefix
    prefix=$(configParser "global" "prefix" "images.cfg")
    value="${prefix}-${value}"
  fi
  replaceCompose "${string}" "${aboriginal}" "${value}"
}
