#!/usr/bin/env bash
# standard

# 是否符合正则
function sre() {
  local string=$1
  local regex=$2
  if [[ $string =~ $regex ]]; then
    echo true
  else
    echo false
  fi
}

SED_BAK_FILE="\"\""
SED_OPTION="-i $SED_BAK_FILE"

# 替换文本内容
function fcg() {
  local source=$1
  local new=$2
  local file=$3
  local operate=$4
  case "$operate" in
  r | replace)
    replace "$source" "$new" "$file"
    ;;
  a | add)
    local pattern='^[0-9]+$'
    if sre "$source" "$pattern"; then
      add_line "$source" "$new" "$file"
    else
      echo "参数行（或多行）为： $source ，不正确（^[0-9]+$）"
      exit 1
    fi
    ;;
  d | delete)
    local pattern='^[0-9]+$'
    if sre "$source" "$pattern"; then
      delete_line "$source" "$new" "$file"
    else
      echo "参数行（或多行）为： $source ，不正确（^[0-9]+$）"
      exit 1
    fi
    ;;
  l | line)
    local pattern='^[0-9]+(,[0-9]+)?$'
    if sre "$source" "$pattern"; then
      replace_line "$source" "$new" "$file"
    else
      echo "参数行（或多行）为： $source ，不正确（^[0-9]+(,[0-9]+)?$）"
      exit 1
    fi
    ;;
  *)
    replace_all "$source" "$new" "$file"
    ;;
  esac
}

function replace_all() {
  sed "$SED_OPTION" "s/$1/$2/g" "$3"
}

function replace() {
  sed "$SED_OPTION" "s/$1/$2" "$3"
}

function replace_line() {
  sed "$SED_OPTION" "$1s/.*/$2/" "$3"
}

function add_line() {
  sed "$SED_OPTION" "$1i\\
$2" "$3"
}

function delete_line() {
  sed "$SED_OPTION" "$1d" "$3"
}

function print_string_by_some() {
  # 输入字符串
  input_string="$1"

  # 使用字符串操作分割字符串
  IFS='.' read -ra parts <<<"$input_string"

  # 初始化左边的字符串为空，右边的字符串为最后一个部分
  left_part=""
  right_part=${parts[${#parts[@]} - 1]}

  # 从最后一个部分开始向前遍历，将每个部分添加到左边的字符串中
  for ((i = ${#parts[@]} - 2; i >= 0; i--)); do
    left_part="${parts[i]}.$left_part"
  done

  # 去除最后一个点号
  left_part=${left_part%?}

  # 输出左边的字符和右边的字符
  echo "左边的字符：$left_part"
  echo "右边的字符：$right_part"
}
