#!/bin/bash
#用于输出艺术字
# e.g. convert_text v0.0.1-release1

declare -A Z_ASCII_COLLECTION Z_COLOR_COLLECTION
Z_ASCII_COLLECTION=(
  ["0"]="____  \n/ __ \ \n| |  | |\n| |__| |\n\____/ \n"
  ["1"]="__   \n/_ |  \n| |  \n  | |  \n  |_|  \n"
  ["2"]="____   \n|___ \  \n__) | \n/ __/  \n|_____| \n"
  ["3"]="_____  \n|___ /  \n|_ \  \n___) | \n|____/  \n"
  ["4"]="_  _   \n| || |  \n| || |_ \n|__   _|\n|_|  \n"
  ["5"]="_____  \n| ____| \n|___ \  \n___) | \n|____/ \n"
  ["6"]="__    \n/ /_   \n| '_ \  \n| (_) | \n\___/  \n"
  ["7"]="______  \n|____  | \n/ /  \n/ /   \n/_/    \n"
  ["8"]="___   \n( _ )  \n/ _ \  \n| (_) | \n\___/  \n"
  ["9"]="___   \n/ _ \  \n| (_) | \n\__, | \n/_/ \n"
  ["."]="\n    \n     \n_ \n(_)\n"
  ["-"]="\n    \n_____ \n|_____|\n  \n"
  ["v"]="\n__   __ \n\ \ / / \n\ V /  \n\_/   \n"
  ["r"]="\n_ __  \n| '__| \n| |    \n|_|    \n"
  ["e"]="\n___   \n/ _ \  \n|  __/  \n\___|  \n"
  ["l"]="_    \n| |   \n| |   \n| |   \n|_|   \n"
  ["a"]="\n__ _  \n / _\` | \n| (_| | \n\__,_| \n"
  ["s"]="\n___   \n/ __|  \n\__ \\  \n|___/  \n"
  ["b"]="_     \n| |__  \n| '_ \ \n| |_) |\n|_.__/ \n"
  ["t"]="_     \n| |_   \n| __|  \n| |_   \n \__|  \n"
  ["x"]="\n__  __ \n\ \/ / \n >  <  \n/_/\_\ \n"
  ["m"]="\n_ __ ___  \n| '_ \` _ \ \n| | | | | |\n|_| |_| |_|\n"
)

Z_COLOR_COLLECTION=(
  ["red"]="\033[0;31m"
  ["r"]="\033[0;31m"
  ["green"]="\033[0;32m"
  ["g"]="\033[0;32m"
  ["blue"]="\033[0;34m"
  ["b"]="\033[0;32m"
  ["yellow"]="\033[33m"
  ["y"]="\033[33m"
  ["purple"]="\033[35m"
  ["p"]="\033[35m"
  ["skyblue"]="\033[36m"
  ["s"]="\033[36m"
  ["white"]="\033[37m"
  ["w"]="\033[37m"
  ["black"]="\033[30m"
  ["dark_gray"]="\033[1;30m"
  ["light_blue"]="\033[1;34m"
  ["light_green"]="\033[1;32m"
  ["cyan"]="\033[0;36m"
  ["light_cyan"]="\033[1;36m"
  ["light_red"]="\033[1;31m"
  ["light_purple"]="\033[1;35m"
  ["brown"]="\033[0;33m"
  ["light_gray"]="\033[0;37m"
  ["black_write_bg"]="\033[40;37m"
  ["bg"]="\033[40;37m"
  ["red_black_bg"]="\033[41;30m"
  ["rg"]="\033[41;30m"
  ["green_blue_bg"]="\033[42;34m"
  ["gg"]="\033[42;34m"
  ["yellow_blue_bg"]="\033[43;34m"
  ["yg"]="\033[43;34m"
  ["blue_black_bg"]="\033[44;30m"
  ["purple_black_bg"]="\033[45;30m"
  ["skyblue_black_bg"]="\033[46;30m"
  ["white_blue_bg"]="\033[47;34m"
  ["red_underline"]="\033[4;31m"
  ["ru"]="\033[4;31m"
  ["red_blink"]="\033[5;31m"
  ["none"]="\033[0m"
  ["n"]="\033[0m"
)

# ASCII 字符输出
function convert_text() {
  local input_text=$1
  local length=${#input_text}
  local converted_array=()
  local color=$2
  if [ -z "${color}" ]; then
    color="${Z_COLOR_COLLECTION[none]}"
  fi

  for ((i = 0; i < length; i++)); do
    local char="${input_text:i:1}"
    local converted="${Z_ASCII_COLLECTION[$char]}"
    if [ -z "$converted" ]; then
      # echo "存在不正确的字符"
      exit 1
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
  local color=$1
  local now_color
  if [ -z "$color" ]; then
    now_color="${Z_COLOR_COLLECTION[none]}"
  else
     now_color="${Z_COLOR_COLLECTION[$color]}"
    if [ -z "$now_color" ]; then
      now_color="${Z_COLOR_COLLECTION[none]}"
    fi
  fi
  echo "$now_color"
}

function print_color() {
  local mes=$1
  local color=$2
  color=$(enter_color "$color")
  printf "${Z_COLOR_COLLECTION[$color]}%s${Z_COLOR_COLLECTION[none]}\n" "$mes"
}

#input_text="$1"
#convert_text "$input_text"
