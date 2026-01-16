#!/usr/bin/env bash

### 字符串处理 ###
# 小写
function toLower() {
  local str="$1"
  sendLog "$str 进行了转小写处理" 0 &>/dev/null
  echo "$str" | tr '[:upper:]' '[:lower:]'
}

# 大写
function toUpper() {
  local str="$1"
  sendLog "$str 进行了转大写处理" 0 &>/dev/null
  echo "$str" | tr '[:lower:]' '[:upper:]'
}

# 格式化
function trim() {
  echo "$1" | awk '{$1=$1};1'
}

# 格式化function，获取函数名称
function trimFunction() {
  local trimmed
  trimmed=$(trim "$1")
  trimmed=${trimmed//\(/}
  trimmed=${trimmed//\)/}
  echo "$trimmed"
}

# 提取section: 提取[]中间的内容并格式化
function extract_bracket_content() {
  local line="$1"
  local content=""

  if [[ "$line" =~ \[(.*)\] ]]; then
    content="${BASH_REMATCH[1]}"
    content=$(trim "$content")
    echo -n "$content"
    return 0
  else
    # 不匹配时返回空字符串，退出码1
    echo -n ""
    return 1
  fi
}

# 根据逗号分割字符串
function splitByComma() {
  local array string=$1
  IFS=',' read -ra array <<<"$string"
  echo "${array[*]}"
}

# 替换字符串内容
function replaceString() {
  # 被替换的字符串
  local string=$1
  # 匹配源
  local aboriginal=$2
  # 被替换值
  local replaced=$3
  echo "${string//${aboriginal}/${replaced}}"
}

# 替换{{ xxx }}
function replaceCompose() {
  replaceString "$1" "\{\{ $2 \}\}" "$3"
}

function checkRepeat() {
  local my_array seen item
  # shellcheck disable=SC2206
  my_array=($*)

  declare -A seen
  for item in "${my_array[@]}"; do
    if [ -n "${seen[$item]}" ]; then
      sendLog "数组中存在相同字符串: $item" 3
      exit 1
    else
      seen[$item]=1
    fi
  done

}

# 获取install_xxx.sh的xxx
function get_install_name() {

  local input_str="$1"

  echo "$input_str" | awk '
    /.*\/install_(.*)\.sh$/ {
      sub(/.*install_/, "", $0)
      sub(/\.sh$/, "", $0)
      print $0
    }
  '

}

# 查找给入字符串是否在字符串数组2中
# 用法：string_contains  <search> <element1> [element2 ...]
function string_contains() {

  local search
  local -a array=()

  search="$1"
  shift
  array=("$@")

  # 容错校验
  if [[ -z "$search" || ${#array[@]} -eq 0 ]]; then
    sendLog "search:$search is null or array:${array[*]} is null!" 3 &>/dev/null
    return 1
  fi

  # 转为关联数组（哈希表），O(1)查找
  local -A hash_map=()
  for element in "${array[@]}"; do
    hash_map["$element"]=1
  done

  # 判断是否存在
  if [[ -n "${hash_map[$search]}" ]]; then
    sendLog "search:$search is in array:${array[*]} !" 0 &>/dev/null
    return 0
  else
    sendLog "search:$search is not in array:${array[*]} !" 0 &>/dev/null
    return 1
  fi
}
