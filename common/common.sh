#!/bin/bash
# 存放公共方法

# 使用方法函数
function usage() {
  echo -e "\033[1musage: common.sh [ --help]
    <--ip> \n
    test        <\"array\">          add something to describe this
    e.g.
    source \"\${ZHOME}\"common/common.sh
    source \"\${ZHOME}\"common/common.sh --test \"a b\"
    ...\033[0m"
  exit 1
}

### 字符串处理 ###
# 小写
function toLower() {
  local str="$1"
  echo "$str" | tr '[:upper:]' '[:lower:]'
}

# 大写
function toUpper() {
  local str="$1"
  echo "$str" | tr '[:lower:]' '[:upper:]'
}

# 格式化
function trim() {
  local trimmed=${1%% }
  local trimmed=${trimmed## }
  echo "$trimmed"
}


### 配置模块 ###

# 获取配置 section key file values
function configParser() {
  # section
  local section="${1}"
  # key
  local needed_key="${2}"
  # file
  local config_file="${3}"
  # values
  local new_values="${4:-}"
  find_section=false
  line_number=1
  while read -r line; do
    if [[ ${line} == \[${section}\]* ]]; then
      find_section=true
    elif [[ ${find_section} == true && (${line} == \[* || ${line} == \#* || -z ${line}) ]]; then
      sendLog "key: ${needed_key} in section: [${section}] not find" &>/dev/null
      echo ""
      break
    elif [[ ${find_section} == true ]]; then
      IFS="=" read -r key val <<<"${line}"
      key=$(trim "${key}")
      val=$(trim "${val}")
      # shellcheck disable=SC2053
      if [[ ${needed_key} == ${key} ]]; then
        if [[ ! ${new_values} ]]; then
          echo "${val}"
          uppercase_string=$(echo "${section}_${needed_key}" | tr '[:lower:]' '[:upper:]')
          eval export "${uppercase_string}"="${val}"
        else
          if [[ -z ${val} ]]; then
            sendLog "old value is empty, adding new value: ${new_values}"
            sed -i.bak "${line_number}s!${line}!${key} = ${new_values}!g" "${config_file}"
          else
            sendLog "changing value: ${val} to ${new_values}"
            sed -i.bak "${line_number}s!${val}!${new_values}!g" "${config_file}"
          fi
        fi
        break
      fi
    fi
    line_number=$((line_number + 1))
  done < <(cat "${config_file}")
}

# 读取配置文件
function readConfig() {
  local config_file="$1"
  # 读取 cfg 文件的内容
  while read -r line; do
    # 忽略注释和空行
    if [[ "${line}" =~ ^[[:space:]]*# || -z "${line}" ]]; then
      continue
    fi

    # 解析变量名和变量值
    if [[ "${line}" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
      section=${BASH_REMATCH[1]}
    elif [[ "${line}" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      varname=${BASH_REMATCH[1]}
      value=${BASH_REMATCH[2]}
      # 将变量名转换为大写，并添加 section 前缀
      varname="$(echo "${section}_${varname}" | tr '[:lower:]' '[:upper:]')"
      # 检查变量名是否已经存在
      if [[ -n "${!varname:-}" ]]; then
        sendLog "已经存在变量: ${varname} ，将进行覆盖" 2
        # exit 1
      fi
      # 导出变量
      eval export "${varname}"="${value}"
    fi
  done <"${config_file}"
}

### 文件确认模块 ###

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
    sendLog "File exists: ${file_name}"
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
    sendLog "Directory exists: ${dir_name}"
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

### 随机数模块 ###
# 取范围内随机数，位数不能超过9
function urandomIntInLim() {
  local min=$1
  local max=$2
  local length=${3:-5} # 如果未指定，则默认为 20

  if (( min > max )); then
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

### 日志管理 ###
# 通用日志管理
function sendLog() {
  local LEVEL="INFO - "
  case $2 in
  0)
    if [ "${LOG_LEVEL}" == "debug" ]; then
      LEVEL="DEBUG - "
    else
      return
    fi
    ;;
  1)
    LEVEL="INFO - "
    ;;
  2)
    LEVEL="WARNING - "
    ;;
  3)
    LEVEL="ERROR - "
    ;;
  4)
    LEVEL="CRITICAL - "
    LOG_CONSOLE_PRINT="true"
    ;;
  *)
    LEVEL="INFO - "
    ;;
  esac

  printf "%-25s%s\n" "$(date '+%Y-%m-%d %H:%M:%S.%3N')" " ${LEVEL}$1" >>"${LOG_FILE}"

  if [ "${LOG_CONSOLE_PRINT}" == "true" ]; then
    printf "%-25s%s\n" "$(date '+%Y-%m-%d %H:%M:%S.%3N')" " ${LEVEL}$1"
  fi
}


readConfig "${SHELL_HOME}global.cfg"
