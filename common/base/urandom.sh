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
  awk -v a="${num}" -v b=1 'BEGIN{print a+b-b}'
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

# 随机长度的中文
function urandomZhongwen() {
  # shellcheck disable=SC2046
  # shellcheck disable=SC2005
  echo "测试"
}

# 再给定的数组长度中，随机给一个Index
function urandomIndex() {
  # shellcheck disable=SC2155
  local index="${1:-1}" num=$(urandomInt 3)
  echo $((num % index))
}

# 数组中随便拿一个出来
function urandomInArray() {
  # shellcheck disable=SC2206
  local arr=($*)
  echo "${arr[$(urandomIndex ${#arr[*]})]}"
}

# 生成随机json数组
# e.g. urandomJsonArray "key" "name" "value"
function urandomJsonArray() {
  local key=${1:-urandom} value i j array
  shift 1
  # shellcheck disable=SC2206
  value=($*)
  if [ -z "$URANDOM_NUM" ]; then
    # not 0
    URANDOM_NUM=$((1 + $(urandomInt 1)))
  fi
  if [ "${#value[*]}" -eq 0 ]; then
    sendLog "run fuc :\`urandomJsonArray\` value is empty!" 0 &>/dev/null
    echo "[{\"${key}\":\"null\"}]"
    return 1
  fi
  # shellcheck disable=SC2004
  for ((i = 1; i <= $URANDOM_NUM; i++)); do
    array+="{"
    for j in ${value[*]}; do
      array+="\"${j}\":\"$(urandomStr 8)\""
      if [ "${j}" != "${value[${#value[*]} - 1]}" ]; then
        array+=","
      fi
    done
    array+="}"
    if [ "${i}" != "${URANDOM_NUM}" ]; then
      array+=","
    fi
  done
  echo "[$array]"

}

# 给入一个数字，生成小于等于他的整数
function urandom_int_by_number() {

  local max_num=${1:-3}

  random_num=$((RANDOM % (max_num + 1)))

  echo "$random_num"


}
