#!/usr/bin/env bash

### 配置模块 ###
# 依赖日志模块、字符串处理模块、文件处理模块
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
  # check file
  config_file=$(checkCfgFile "$config_file")
  local find_section=false
  local line_number=1
  # 最后一行不为空会影响读取
  local last_line
  last_line=$(tail -n 1 "$config_file")
  if [[ -n "$last_line" ]]; then
      echo >> "$config_file"
  fi
  while read -r line; do
    if [[ ${line} == \[${section}\]* ]]; then
      find_section=true
    elif [[ ${find_section} == true && (${line} == \[*) ]]; then
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
          eval export "${uppercase_string}"="$(trim "${val}")"
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
  local val=""
  local varname=""
  local section=""

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
      val=${BASH_REMATCH[2]}
      # 将变量名转换为大写，并添加 section 前缀
      varname="$(echo "${section}_${varname}" | tr '[:lower:]' '[:upper:]')"
      # 检查变量名是否已经存在
      if [[ -n "${!varname:-}" ]]; then
        sendLog "已经存在变量: ${varname} ，将进行覆盖" 2 &> /dev/null
        # exit 1
      fi
      # 导出变量
      eval export "${varname}"="$(trim "${val}")"
    fi
  done <"${config_file}"
}