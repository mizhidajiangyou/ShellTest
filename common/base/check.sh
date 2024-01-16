#!/usr/bin/env bash

### 环境检测模块 ###
# 检测命令是否可用
function checkCommand() {
  local com="$1"
  if ! command -v "$com" &>/dev/null; then
    sendLog "检测命令$com 不可用。 " 3 &>/dev/null
    return 1
  else
    sendLog "检测命令$com 可用。 " 0 &>/dev/null
    return 0
  fi
}

# 检测环境容量
function checkAvailable() {

  # 目录最小容量
  local min=${1:-100}

  # 需要判断的目录
  local check_dir=${2:-/}

  # 获取根目录的可用容量
  available_space=$(df -h --output=avail "$check_dir" | tail -n 1)

  # 提取数字部分
  available_space_gb=$(echo "$available_space" | awk '{gsub("G","") ;print $1}')

  # 检查容量是否小于100G
  if ((available_space_gb < min)); then
    sendLog "失败：$check_dir 目录可用容量低于 $min G。当前可用容量为 $available_space_gb GB" 3
  else
    sendLog "成功：$check_dir 目录可用容量为 $available_space_gb GB" 1 g
  fi
}

# 判断IP是否可用
function checkIp() {
  local ip_address=$1
  if ping -c 1 -W 1 -s 1 "${ip_address}" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

# 等待ip可用
function waitIpReady() {
  local ip_address=$1
  local retries=0
  while true; do
    if checkIp "$ip_address"; then
      sendLog "ping $ip_address 成功!" 0
      break
    else
      retries=$((retries + 1))
      sendLog "第 $retries 次 Ping ${ip_address}  失败" 0
      if [ $retries -eq "${NETWORK_MAX_RETRY}" ]; then
        sendLog "ping ${ip_address} 达到最大重试次数，退出循环" 2
        # 错误情况下无法进行后续操作
        exit 1
        # break
      fi
    fi
    sleep "${NETWORK_RETRY_DELAY}"

  done

}

function checkSSHKey() {
    local  key_file="$HOME/.ssh/id_rsa"

    if [ ! -f "$key_file" ]; then
        sendLog "Generating SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$key_file" -N ""
        sendLog "SSH key generated."
    else
        sendLog "SSH key already exists." 0
    fi
}
