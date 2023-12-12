#!/usr/bin/env bash
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

function check_bash() {
  read -r shebang <"$0"
  interpreter="${shebang#!*bin/}"
  interpreter="${interpreter%% *}"
  if [ -z "$interpreter" ]; then
    if [[ "${SHELL##*/}" == *zsh* ]]; then
      echo "不支持zsh，请修改shebang行指定默认解释器为bash。"
      exit 1
    fi
    interpreter=$SHELL
  else
    if [[ "${interpreter##*/}" == *zsh* ]]; then
      echo "不支持zsh，请修改shebang行指定默认解释器为bash。"
      exit 2
    fi
    interpreter=${shebang#*!}
  fi
  min_version='4.0.0'
  now_version=$($interpreter --version | head -n 1 | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+")
  small_version=$(echo -e "$now_version\n$min_version" | sort -V | head -n 1)
  if [ "${small_version}" != "$min_version" ]; then
    echo "当前使用的默认解释器为:${interpreter}版本为$now_version,低于最低bash版本要求。"
    exit 1
  fi
}

function source_all_base_function() {
  # local fun_file=(check  configuration decorator file font logger notice string urandom)
  if [ -z "${SHELL_HOME}" ]; then
    echo "请先配置变量SHELL_HOME。"
    exit 1
  fi
  cd "${SHELL_HOME}" || exit 127
  source common/font.sh
  source common/print.sh
  source common/check.sh
  source common/configuration.sh
  source common/decorator.sh
  source common/file.sh
  source common/logger.sh
  source common/notice.sh
  source common/string.sh
  source common/urandom.sh
  cd - || exit 127
}

# 主函数
function _main() {
  check_bash
  source_all_base_function
  local cfg_name="global.cfg"
  # 文件不存在则创建
  if [[ ! -f "${SHELL_HOME}${cfg_name}" ]]; then
    print_color "No file ${cfg_name} in ${SHELL_HOME},init it now !" r
    sleep 3
    {
      # shellcheck disable=SC2016
      echo '# 全局配置
             # 日志
             [log]
             level = debug
             console_print = true
             file = ${SHELL_HOME}res/log/shell.log

             # 锁
             [lock]
             pre_name = ${SHELL_HOME}res/lock/.z_lock_

             [dingding]
             # 是否@所有人
             all = false
             # 是否启用
             use = true'
    } >"${SHELL_HOME}${cfg_name}"
  fi
  # 配置文件名称
  readConfig "${SHELL_HOME}${cfg_name}"
  # 确保日志文件存在
  checkFile "${LOG_FILE}" "force" &>/dev/null
}

_main

# sleep 123123
