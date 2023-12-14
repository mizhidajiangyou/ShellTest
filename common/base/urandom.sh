#!/usr/bin/env bash

### 随机数模块 ###
# 取范围内随机数，位数不能超过9
function urandomIntInLim() {
  local min=$1
  local max=$2
  local length=${3:-5} # 如果未指定，则默认为 20

  if ((min > max)); then
    echo 0
  fi

  local num
  num=$(od -An -N"${length}" -tu4 /dev/urandom | tr -d ' ')
  num=$((num % (max - min + 1) + min))

  echo "$num"
}

# 生成随机位数的整数
function urandomInt() {
  local ur_length="${1:-3}"

  num=$(head /dev/urandom -n 10000 | tr -dc 0-9 | head -c "${ur_length}")
  # 去掉0开头的
  awk -v a="${num}" -v b=1 'BEGIN{print a+b}'
}

# 随机长度的字符串
function urandomStr() {
  local ur_length="${1:-20}"

  # 生成随机字符串
  local str
  str=$(head -c "$((ur_length * 2))" /dev/urandom | base64 | tr -d '/+' | head -c "$ur_length")

  # 输出结果
  echo "$str"
}