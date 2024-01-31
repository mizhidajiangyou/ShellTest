#!/usr/bin/env bash

source scripts/common.sh

function check_available() {
  if ! checkAvailable 100 "$(getPath)"; then
    exit 1
  fi
}

function check_cpu_and_memory() {
  if ! checkCPUMemory 4 8; then
    exit 1
  fi
}

function check_user() {
  local now_user need_user_id user_info
  now_user=$(whoami)
  need_user_id="$(configParser "expect" "user_id" global.cfg)"
  user_info=$(grep "^$now_user:" "/etc/passwd" | awk -F: '{printf "%s:%s",$3,$4}')
  if [ "${user_info}" != "${need_user_id}:${need_user_id}" ]; then
    sendLog "当前用户$now_user,不符合部署的用户需求,应该使用配置所需的${need_user_id}:${need_user_id}用户进行部署。" 2 y
    exit 1
  fi
  sendLog "当前用户为$now_user,权限为$user_info"
}

function check_command_ok() {
  checkCommand "docker"
}

function check_port_ok() {
  local service_list ser port
  service_list=$(configParser install service images.cfg)
  for ser in ${service_list[*]}; do

    port="$(configParser "${ser}" "port" images.cfg)"
    # 校验port
    if ! checkLocalPort "$port";then
      sendLog "校验端口: ${port}被使用。" 3
      exit 1
    fi
  done

}

function main() {
  check_user
  check_command_ok
  check_cpu_and_memory
  check_available
  check_port_ok
}

main
