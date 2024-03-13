#!/usr/bin/env bash
# 该脚本用于linux系统间快速创建统一账户，依赖root
#shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh
function main() {
  if [ "$(whoami)" != "root" ]; then
    echo "user root to continue!"
    exit 1
  fi
  if [ -z "${HOSTS_MACHINES}" ]; then
    sendLog "配置文件中的地址数目为0，请检查" 3
    exit 1
  fi
  local i
  for i in ${HOSTS_MACHINES[*]}; do
    # 先检测地址是否可以连通
    waitIpReady "$i"
    # shellcheck disable=SC2001
    expectBash "root" "${i}" "${ROOT_PASSWD}" "useradd -m -p $(echo "$INIT_PASSWORD" | sed 's/\$/\\$/g') -u $INIT_USER_ID -U $INIT_USER_NAME"
    sendLog "Init $i user $INIT_USER_NAME fi!" 0
  done

}
# root账户密码
ROOT_PASSWD="password"
# 初始化的用户
INIT_USER_NAME="mz024"
# 用户id
INIT_USER_ID="2024"
# 用户密码
INIT_PASSWORD=$(perl -e 'print crypt("mypassword", "password")')
main
