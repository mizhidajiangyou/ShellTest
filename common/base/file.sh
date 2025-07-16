#!/usr/bin/env bash

### 文件操作模块 ###

# 进入指定目录，如果不存在则创建
function intoPath() {
  local path="${1}"
  local force="${2}"

  if [[ ! -d "${path}" ]]; then
    if [[ "${force}" == "force" ]]; then
      if mkdir -p "${path}" && cd "${path}"; then
        sendLog "Created directory and changed to it: ${path}"
      else
        sendLog "Failed to create directory: ${path}" 3
        return 1
      fi
    else
      sendLog "Error! Directory does not exist: ${path}" 3
      return 1
    fi
  else
    if cd "${path}"; then
      sendLog "Changed to directory: ${path}"
    else
      sendLog "Failed to change to directory: ${path}" 3
      return 1
    fi
  fi
  return 0
}

# 检查指定文件是否存在，如果不存在则创建
function checkFile() {
  local file_name="${1}"
  local file_force="${2}"
  if [ -z "${file_name}" ];then
    sendLog "not give ${file_name}" 2
    return 1
  fi
  if [[ ! -f "${file_name}" ]]; then
    if [[ "${file_force}" == "force" ]]; then
      # shellcheck disable=SC2155
      local father_dir="$(dirname "${file_name}")"
      if mkdir -p "${father_dir}" && touch "${file_name}"; then
        sendLog "Created file: ${file_name}"
      else
        sendLog "Failed to create file: ${file_name}" 3
        return 1
      fi
    else
      sendLog "Error! File does not exist: ${file_name}" 3
      return 1
    fi
  else
    sendLog "File exists: ${file_name}" 0
  fi
  return 0
}

# 检查指定目录是否存在，如果不存在则创建
function checkDir() {
  local dir_name="${1}"
  local dir_force="${2}"

  if [[ ! -d "${dir_name}" ]]; then
    if [[ "${dir_force}" == "force" ]]; then
      if mkdir -p "${dir_name}"; then
        sendLog "Created directory: ${dir_name}"
      else
        sendLog "Failed to create directory: ${dir_name}" 3
        return 1
      fi
    else
      sendLog "Error! Directory does not exist: ${dir_name}" 3
      return 1
    fi
  else
    sendLog "Directory exists: ${dir_name}" 0
  fi
  return 0
}

# 检查指定变量是否存在或非空，可选是否强制检查
function checkVal() {
  local val="${1}"
  local val_name="${2}"
  local val_check="${3}"

  if [[ -z "${val_name}" ]]; then
    sendLog "Warning: val_name is empty. Skipping val_force_check." 2
  fi

  if [[ "${val_check}" == "force" && -z "${val}" ]]; then
    sendLog "Error! ${val_name} is required." 3
    return 1
  elif [[ -n "${val}" ]]; then
    sendLog "${val_name} is ${val}"
  else
    sendLog "Warning: ${val_name} is empty." 2
  fi
  return 0
}

# 变量为空则结束脚本
function haveVal() {
  local val="${1}"
 if [[ -z "${val}" ]]; then
    sendLog "Val is empty." 3
    exit 1
  fi
}

# 寻找文件是否存在，会根据目录层级往前追述5层
function checkCfgFile() {
  # 定义要查找的文件名
  local filename="$1"
  # 判断是否为绝对路径
  if [[ $filename == /* ]]; then
    sendLog "文件： $filename 为绝对路径，不进行查找。 " 0  &>/dev/null
    echo "$filename"
    return 0
  fi
  # 定义要向前查找的层数
  local layers=3

  # 获取当前目录
  # shellcheck disable=SC2155
  local current_dir=$(pwd)

  # 逐层向前查找文件
  for ((i = 0; i <= layers; i++)); do
    # 检查当前目录是否存在指定文件
    if [ -f "$current_dir/$filename" ]; then
      sendLog "匹配到文件： $current_dir/$filename" 0 &>/dev/null
      echo "$current_dir/$filename"
      return 0
    else
      sendLog "匹配文件：  $current_dir/$filename 失败，将在上一层目录中寻找" 2 &>/dev/null
      # 切换到上一级目录
      current_dir=$(dirname "$current_dir")
    fi
  done

  sendLog "未找到文件 $filename"
  return 1
}

# 锁操作
function zLock() {
  local lock_name="$1"
  local operation="$2"
  local now_lock_name="${LOCK_PRE_NAME}${lock_name}"

  checkVal "${lock_name}" "私有锁${lock_name}" "force"

  case ${operation} in
  add)
    echo 1 >"${now_lock_name}"
    ;;
  remove | reset)
    echo 0 >"${now_lock_name}"
    ;;
  look)
    if [ ! -f "${now_lock_name}" ]; then
      sendLog "No such lock file !" 2
      checkFile "${now_lock_name}" "force"
      return 1
    fi

    if [[ $(<"${now_lock_name}") != 1 ]]; then
      sendLog "lock is not 1" 0
    else
      sendLog "lock is $(<"${now_lock_name}")" 4
      return 127
    fi
    ;;
  create)
    checkFile "${now_lock_name}" "force"
    ;;
  *)
    sendLog "Unsupported lock operation: ${operation}" 3
    return 3
    ;;
  esac
}

function waitLock() {
  local lock_name=$1
  local counter=1
  local num=12
  local time=10
  while [ $counter -le $num ]; do
    if [ -f "$lock_name" ]; then
      sleep $time
      counter=$((counter + 1))
    else
      touch "$lock_name"
      return 0
    fi
  done
  exit 1

}