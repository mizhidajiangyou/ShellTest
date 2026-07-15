#!/usr/bin/env bash

### 配置模块 ###
# 依赖日志模块、字符串处理模块、文件处理模块
# 获取配置 section key file values
function configParser() {
  local section="$1"
  local needed_key="$2"
  local config_file="$3"
  local new_values="${4:-}"

  config_file=$(checkCfgFile "$config_file")

  local find_section=false
  local line_number=0
  local line key val

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))

    if [[ "$line" == "[$section]"* ]]; then
      find_section=true
      continue
    fi

    # 进入下一个 section，说明 key 未找到
    if [[ "$find_section" == true && "$line" == "["* ]]; then
      sendLog "key: ${needed_key} in section: [${section}] not found" &>/dev/null
      echo ""
      return 1
    fi

    if [[ "$find_section" == true && "$line" == *"="* ]]; then
      key=$(trim "${line%%=*}")
      val=$(trim "${line#*=}")

      if [[ "$needed_key" == "$key" ]]; then
        # ===== 读取模式 =====
        if [[ -z "$new_values" ]]; then
          echo "$val"
          return 0
        fi

        # ===== 写入模式 =====
        if [[ -z "$val" ]]; then
          sendLog "old value is empty, adding new value: ${new_values}" &>/dev/null
        else
          sendLog "changing value: ${val} to ${new_values}" &>/dev/null
        fi

        # 转义 sed 特殊字符，避免注入
        local escaped_new
        escaped_new=$(printf '%s\n' "$new_values" | sed 's/[&/\]/\\&/g')

        # shellcheck disable=SC2094
        sed -i.bak "${line_number}s!\(^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\).*!\1${escaped_new}!" "$config_file"
        return 0
      fi
    fi
  done <"$config_file"

  # section 本身就没找到
  sendLog "section: [${section}] not found" &>/dev/null
  echo ""
  return 1
}

# 读取配置文件
function readConfig() {
  local config_file="$1"
  local val="" varname="" section="" combined

  # 读取 cfg 文件的内容
  while IFS= read -r line || [[ -n "$line" ]]; do
    # 忽略注释和空行
    if [[ "${line}" =~ ^[[:space:]]*# || -z "${line}" ]]; then
      continue
    fi

    # 解析变量名和变量值
    if [[ "${line}" =~ ^\[([a-zA-Z0-9_-]+)\]$ ]]; then
      section=${BASH_REMATCH[1]}
    elif [[ "${line}" =~ ^([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      varname=${BASH_REMATCH[1]}
      val=${BASH_REMATCH[2]}
      # 将变量名转换为大写，并添加 section 前缀
      # varname="$(echo "${section}_${varname}" | tr '[:lower:]' '[:upper:]')"
      combined="${section}_${varname}"
      varname="${combined^^}"
      # 检查变量名是否已经存在
      if [[ -n "${!varname:-}" ]]; then
        sendLog "已经存在变量: ${varname} ，将进行覆盖" 2 &>/dev/null
        # exit 1
      fi
      # 导出变量
      eval export "${varname}"="$(trim "${val[@]}")"
    fi
  done <"${config_file}"
}

# 读取一个section下的所有key 或者 values
function getConfigSection() {
  local section="$1"
  local config_file="$2"
  local type="${3:-key}"

  config_file=$(checkCfgFile "$config_file")

  local find_section=false
  local line key val

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 跳过空行
    [[ -z "$line" ]] && continue

    if [[ "$line" == "[$section]"* ]]; then
      find_section=true
      continue
    fi

    # 进入下一个 section，退出
    if [[ "$find_section" == true && "$line" == "["* ]]; then
      break
    fi

    # 在目标 section 内，且是 key=value 格式
    if [[ "$find_section" == true && "$line" == *"="* ]]; then
      key=$(trim "${line%%=*}")
      val=$(trim "${line#*=}")

      if [[ "$type" == "key" ]]; then
        echo "$key"
      else
        echo "$val"
      fi
    fi
  done <"$config_file"
}

# 保留一份配置文件中的跟给入section一致的key=value
function filter_config_sections() {
  if [[ $# -lt 2 ]]; then
    sendLog "Error: Usage: $0 <config_file> <section1> [section2 ...]" 3 &>/dev/null
    return 1
  fi

  local config_file="$1"
  shift
  config_file=$(checkCfgFile "$config_file")

  # 用关联数组：赋值即去重，且后续查找 O(1)
  local -A keep_map=()
  local section
  for section in "$@"; do
    keep_map["$section"]=1
  done

  local current_section="" find_section=false line
  while IFS= read -r line || [[ -n "$line" ]]; do

    if [[ -z "$line" ]]; then
      [[ "$find_section" == true ]] && echo ""
      continue
    fi

    if [[ "$line" == "["* ]]; then
      local tmp="${line#*[}"
      current_section="${tmp%%]*}"
      if [[ -n "${keep_map["$current_section"]+x}" ]]; then
        find_section=true
        echo "$line"
      else
        find_section=false
      fi
    elif [[ "$find_section" == true ]]; then
      echo "$line"
    fi
  done < "$config_file"

  return 0
}
