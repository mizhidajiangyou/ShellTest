#!/usr/bin/env bash

source scripts/common.sh

function init_docker_network() {
  # shellcheck disable=SC2155
  local network_name="$(configParser network network_name images.cfg)"
  if ! docker network ls | grep -q "${network_name}"; then
    sendLog "docker network ${network_name} not exist, create it" 1
    docker network create -d bridge "${network_name}" --subnet "$(configParser network subnet images.cfg)"
  else
    sendLog "docker network ${network_name} exist, skip create" 0
  fi

}

function init_config_network() {
   sendLog "init network config.."
   # shellcheck disable=SC2091
   if $(configParser network auto_config images.cfg) ;then
     # shellcheck disable=SC2155
     local net_name="$(configParser network network images.cfg)"
     sendLog "auto config network..."
     if [ "$net_name" == "eth0" ]; then
       ip_list=$(ip a | grep 'state UP' | grep -v noqueue | awk '{gsub(":", "", $2);print $2}')
       # 当前可用的网卡
       ip=$(ifconfig "${ip_list[0]}" | grep broadcast | awk 'NR=1{print $2}')
       sendLog "used ${ip_list[0]} , address $ip"
       # 修改配置中的网络
       configParser network network images.cfg "${ip_list[0]}"
       configParser network local_ip images.cfg "$ip"
     else
       echo "Configuration has been modified, skipping automatic configuration..."
     fi
    fi
}

function do_install() {
  local ser
  ser=$1
  ./install/install_"${ser}".sh
  pushd artifact/"${ser}" &>/dev/null || exit 1
  sendLog "start ${ser} ..."
  if ! ./start.sh; then
    sendLog "start ${ser} failed! " 3
    exit 1
  fi
  popd &>/dev/null || exit 1

}

function main() {
  init_docker_network
  init_config_network
  for_service_do do_install
}

main
