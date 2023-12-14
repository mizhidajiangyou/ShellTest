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
function check_available() {

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