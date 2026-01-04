#!/usr/bin/env bash

### 环境检测模块 ###
# 检测命令是否可用
function checkCommand() {
  local com="$1"
  if ! command -v "$com" &>/dev/null; then
    sendLog "检测命令$com 不可用。 " 3
    exit 1
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
    return 1
  else
    sendLog "成功：$check_dir 目录可用容量为 $available_space_gb GB" 1 g
    return 0
  fi
}

# 确认内存和cpu是否符合规范
function checkCPUMemory() {
  local total_memory cpu_cores need_cpu need_memory
  need_cpu=$(echo "$1" | awk '{result = sprintf("%d", $1); print result}')
  need_memory=$(echo "$2" | awk '{result = sprintf("%d", $1 * 1000000); print result}')
  if [ "$need_cpu" -eq 0 ] || [ "$need_memory" -eq 0 ]; then
    sendLog "错误的cpu或内存入参！" 3
    return 1
  fi
  if [[ $(uname -s) != "Darwin" ]]; then
    total_memory=$(free | awk '/^Mem:/{print $2}')
    cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
  else
    total_memory=$(sysctl -n hw.memsize | awk '{printf "%d", $0/1000}')
    cpu_cores=$(sysctl -n hw.ncpu)
  fi
  sendLog "当前系统cpu核数为：$cpu_cores,内存为${2}GB"

  if [ "${total_memory}" -lt "${need_memory}" ] || [ "${cpu_cores}" -lt "${need_cpu}" ]; then
    sendLog "机器不符合CPU${cpu_cores},内存${2}GB的标准，不符合该标准后续可能无法正常部署。" 3
    return 1
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
  local key_file="$HOME/.ssh/id_rsa"

  if [ ! -f "$key_file" ]; then
    sendLog "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$key_file" -N ""
    sendLog "SSH key generated."
  else
    sendLog "SSH key already exists." 0
  fi
}

function checkLocalPort() {
  local port=$1
  if netstat -tuln | grep -q "${port}" &>/dev/null; then
    sendLog "port ${port} is used." &>/dev/null
    return 1
  else
    sendLog "port ${port} is don't used." 0 &>/dev/null
    return 0
  fi

}

function checkStringIsIp() {
  local ip="$1"
  # 正则表达式解释：
  # ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$
  # 1. 25[0-5]：匹配250-255
  # 2. 2[0-4][0-9]：匹配200-249
  # 3. [01]?[0-9][0-9]?：匹配0-199（允许1位、2位或3位，且不允许前导零超过1位，如012不匹配）
  # 4. ((...)\.){3}：匹配前3段及末尾的.
  # 5. 最后一段与前3段规则相同，结尾为$确保没有多余字符
  if [[ "$ip" =~ ^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$ ]]; then
    sendLog "校验$ip 是合法IP" 0 &>/dev/null
    return 0
  else
    sendLog "校验： $ip 不是是合法IP" 3 &>/dev/null
    return 1
  fi

}

function checkUrlIsOk() {
  local url=$1

  if [ -z "$url" ]; then
    sendLog "请提供要检查的地址，例如: $0 172.22.71.101:15541/api" 3  &>/dev/null
    return 1
  fi

  if curl -sS  "$url" &>/dev/null; then
    sendLog "地址可通: $url" &>/dev/null
    return 0
  else
    sendLog "地址不通: $url" 3 &>/dev/null
    return 1
  fi
}
