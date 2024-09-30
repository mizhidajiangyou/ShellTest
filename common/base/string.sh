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
  local trimmed=${1%% }
  local trimmed=${trimmed## }
  echo "$trimmed"
}

# 格式化function，获取函数名称
function trimFunction() {
  local trimmed
  trimmed=$(trim "$1")
  trimmed=${trimmed//\(/}
  trimmed=${trimmed//\)/}
  echo "$trimmed"
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
