#!/usr/bin/env bash
### 输出模块 ###

# ASCII 字符输出
function convert_text() {
  local input_text=$1
  local length=${#input_text}
  local converted_array=()
  local color=${2:-${Z_COLOR_COLLECTION[none]}}
  for ((i = 0; i < length; i++)); do
    local char="${input_text:i:1}"
    local converted="${Z_ASCII_COLLECTION[$char]:-no_such_char}"
    if [ "$converted" == "no_such_char" ]; then
      # 跳过不存在的字符
      continue
    fi
    converted_array+=("$converted")
  done

  pp=()
  for ((f = 0; f < ${#converted_array[@]}; f++)); do
    local now_f=${converted_array[$f]}
    local is_short=false
    local is_long=false
    # 如果是.，则输出时间隔短一点
    if [ "${now_f}" == "${Z_ASCII_COLLECTION[.]}" ]; then
      is_short=true
    elif [ "${now_f}" == "${Z_ASCII_COLLECTION[m]}" ]; then
      is_long=true
    fi

    IFS="$(printf 'n')" read -d '' -ra lines <<<"$now_f"
    l=0
    for line in "${lines[@]}"; do

      if [ $((l + 1)) -ne ${#lines[@]} ]; then
        line=${line:0:-1}
      fi
      if $is_short; then
        pp[$l]=$(printf "%s%5s" "${pp[$l]}" "${line}")
      elif $is_long; then
        pp[$l]=$(printf "%s%13s" "${pp[$l]}" "${line}")
      else
        pp[$l]=$(printf "%s%9s" "${pp[$l]}" "${line}")
      fi

      l=$((l + 1))
    done

  done

  for ((p = 0; p < 5; p++)); do
    if [ "$p" -eq 0 ]; then
      echo -e "${color}${pp[$p]}"
    elif [ "$p" -eq 4 ]; then
      echo -e "${pp[$p]}${Z_COLOR_COLLECTION[none]}"
    else
      echo "${pp[$p]}"
    fi
  done

}

# 颜色输出
function enter_color() {
  local color=${1:-n}
  local now_color=${Z_COLOR_COLLECTION[$color]:-${Z_COLOR_COLLECTION[none]}}
  echo "$now_color"
}

# 根据颜色输出
function print_color() {
  local mes=$1
  local color=$2
  color=$(enter_color "$color")
  printf "${color}%s${Z_COLOR_COLLECTION[none]}\n" "$mes"
}

### 发里服少
# 百分比进度
function progressBar() {
  # 进度
  local J_NOW=0
  # 总进度
  local J_ALL=100
  # 定义数组长度
  local J_NUM=$1
  if [[ ! $J_NUM =~ ^[0-9]+$ ]]; then
    sendLog "progress_bar 入参错误，非整数！" 3 &>/dev/null
    return 1
  fi
  J_NUM_N=$J_NUM
  # 定义单次增长进度数
  while [ "$J_NUM_N" -ne 0 ]; do
    J_ADD=$((J_ALL / J_NUM))
    J_NOW=$((J_NOW + J_ADD))
    if [ $((J_ALL - J_ADD)) -le $J_NOW ]; then
      echo "[$J_ALL%|$J_ALL%] $2"
    else
      printf "[%s|$J_ALL%%] %s\n\033[1A" $J_NOW "$2"
      sleep 1
    fi
    J_NUM_N=$((J_NUM_N - 1))
  done
}

# 数字倒计时
function countdown() {
  local limit=$1
  local max=$1
  local color="${Z_COLOR_COLLECTION[green]}"
  if [[ ! $limit =~ ^[0-9]+$ ]]; then
    return 1
  fi
  while [ "$limit" -ne 0 ]; do
    if [ "$limit" -eq $((2 * max / 3)) ]; then
      color="${Z_COLOR_COLLECTION[blue]}"
    elif [ "$limit" -eq $((max / 3)) ]; then
      color="${Z_COLOR_COLLECTION[red]}"
    fi
    zAsi "$limit" "$color"
    limit=$((limit - 1))
  done
}

# 数字正数
function countIt() {
  # 正常不需要颜色
  local count=1
  local limit=$1
  # local max=$1
  # local color='\033[0;32m'
  if [[ ! $limit =~ ^[0-9]+$ ]]; then
    return 1
  fi

  while [ $count -le "$limit" ]; do
    #    if [ "$count" -eq $((2 * max / 3)) ]; then
    #      color="\033[0;31m"
    #    elif [ "$count" -eq $((max / 3)) ]; then
    #      color="\033[0;34m"
    #    fi
    #    zAsi $count "$color"
    zAsi $count
    count=$((count + 1))
  done
}

# 输出字后清空
function zAsi() {
  local out=$1
  local color="$2"
  if [ -z "${color}" ]; then
    color='\033[0m'
  fi
  # 移动光标到上方 5 行
  local move_cursor_up="\033[5A"
  # 清除光标位置之上的所有内容
  local clear_above_cursor="\033[J"

  convert_text "$out" "$color"

  sleep 1
  # 移动
  echo -ne "$move_cursor_up"
  # 清除
  echo -ne "$clear_above_cursor"

}

#input_text="$1"
#convert_text "$input_text"
