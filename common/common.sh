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
  # 不能用for导入，否则影响打包，待优化
  pushd "${SHELL_HOME}"common/base &> /dev/null || return 1
  source k8s.sh
  source font.sh
  source print.sh
  source check.sh
  source configuration.sh
  source decorator.sh
  source file.sh
  source logger.sh
  source notice.sh
  source string.sh
  source urandom.sh
  source communication.sh
  source process.sh
  source signal.sh
  source time.sh
  source struct.sh
  popd &> /dev/null || return 1
}

# 主函数
function _main() {
  # 待有缘人优化吧
  # check_bash
  source_all_base_function
  local cfg_name="global.cfg"
  # 文件不存在则创建
  if [[ ! -f "${SHELL_HOME}${cfg_name}" ]]; then
    sendLog "No file ${cfg_name} in ${SHELL_HOME},init it now !" 2 y
    sleep 2
    touch "${SHELL_HOME}${cfg_name}" || exit 1
    cat >"${SHELL_HOME}${cfg_name}" <<EOF
# 全局配置
[global]
find_layers = 1

# 日志
[log]
level = debug
console_print = true
file = ${SHELL_HOME}res/log/shell.log

# 锁
[lock]
pre_name = ${SHELL_HOME}res/lock/.z_lock_

# expect配置
[expect]
# 超时时间
time_out = 3
# 记录文件
result_file = ${SHELL_HOME}res/log/expect.log
# 通配符
prompt = $
# 用户（可不配置）
user =
# 密码 (可不配置)
password =

[network]
# 重试间隔
retry_delay = 1
# 普通房重试次数
retry = 3
# 最大等待时间
max_time = 300
# 最大重试次数
max_retry = 60

[dingding]
# 是否@所有人
all = false
# 是否启用
use = true

[hosts]
# 主机地址列表
machines = '192.168.0.1 192.168.0.2'

[k8s]
namespace = auto-
kubeconfig = ~/.kube/config

EOF
  sendLog "init file successful! please check $cfg_name and retry !" 1 g
  exit 0
  fi
  # 配置文件名称
  readConfig "${SHELL_HOME}${cfg_name}"
  # 确保日志文件存在
  checkFile "${LOG_FILE}" "force" &>/dev/null
  checkFile "${EXPECT_RESULT_FILE}" "force" &>/dev/null
}

_main

# sleep 123123
