#!/bin/bash

# 数字和符号的映射关系
declare -A characters
characters=(
  ["0"]="  ____  \n / __ \ \n| |  | |\n| |  | |\n \____/ \n"
  ["1"]="  __   \n /_ |  \n  | |  \n  | |  \n  |_|  \n"
  ["2"]="  ____   \n |___ \  \n   __) | \n  / __/  \n |_____| \n"
  ["3"]="  _____  \n |___ /  \n   |_ \  \n  ___) | \n |____/  \n"
  ["4"]="  _  _   \n | || |  \n | || |_ \n |__   _|\n    |_|  \n"
  ["5"]="  _____ \n | ____|\n | |__  \n |___ \ \n  ___) |\n"
  ["6"]="   ____  \n  / __ \ \n | / _ |\n | \__, |\n  \____/ \n"
  ["7"]=" ______  \n|____  | \n    / /  \n   / /   \n  /_/    \n"
  ["8"]="  ____  \n / __ \ \n| /  \ |\n| \__/ |\n \____/ \n"
  ["9"]="  ____  \n / __ \ \n| /  \|\n| \__/ |\n \____/ \n"
  ["."]="    \n    \n  ---  \n  (   )\n ___  \n"
)

convert_text() {
  local input_text=$1
  local length=${#input_text}
  local converted_array=()

  for ((i = 0; i < length; i++)); do
    local char="${input_text:i:1}"
    local converted="${characters[$char]}"
    converted_array+=("$converted")
  done

  pp=("" "" "" "" "")
  for ((f = 0; f < ${#converted_array[@]}; f++)); do
    local now_f=${converted_array[$f]}

    IFS="$(printf 'n')" read -d '' -ra lines <<<"$now_f"
    #for ((l = 0; l < ${#lines[@]}; l++)); do
    l=0
    for line in "${lines[@]}"; do

      if [ $((l + 1)) -ne ${#lines[@]} ]; then
        line=${line:0:-1}
      fi
      pp[$l]=$(printf "%s%10s%3s" "${pp[$l]}" "${line}" "")
      l=$((l + 1))
    done

  done
  echo "${pp[0]}"
  echo "${pp[1]}"
  echo "${pp[2]}"
  echo "${pp[3]}"
  echo "${pp[4]}"

}

input_text="$1"
convert_text "$input_text"
