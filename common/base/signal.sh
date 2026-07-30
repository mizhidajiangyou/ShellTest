#!/usr/bin/env bash

### 信号处理 ###

# 已注册的退出清理文件列表，主要用于脚本异常退出时删除临时文件。
__SHELL_TRAP_CLEAN_FILES="${__SHELL_TRAP_CLEAN_FILES:-}"

# 执行退出清理：删除通过 registerExitCleanFile 注册过的临时文件。
function runExitClean() {
  local clean_file
  while IFS= read -r clean_file; do
    if [ -n "${clean_file}" ] && [ -f "${clean_file}" ]; then
      rm -f "${clean_file}"
    fi
  done <<EOF
${__SHELL_TRAP_CLEAN_FILES}
EOF
}

# 注册一个需要在脚本退出时自动删除的文件，并自动启用 EXIT/HUP/TERM 清理 trap。
function registerExitCleanFile() {
  local clean_file=$1
  if [ -z "${clean_file}" ]; then
    return 1
  fi
  __SHELL_TRAP_CLEAN_FILES="${__SHELL_TRAP_CLEAN_FILES}
${clean_file}"
  trap_exit ""
}

# 管理脚本退出类信号：默认启用 EXIT/HUP/TERM 清理；传入任意参数时取消清理 trap。
# shellcheck disable=SC2120
function trap_exit() {
  local action=${1:-}
  if [ -z "${action}" ]; then
    trap runExitClean EXIT HUP TERM
  else
    trap - EXIT HUP TERM
  fi
}

# 管理 Ctrl+C 信号：默认拦截 INT 并打印提示；传入任意参数时恢复默认 INT 行为。
function trap_c() {
  if [ -z "$1" ]; then
    trap "print_color 'end in Ctrl c' r" INT
  else
    trap - INT
  fi
}
