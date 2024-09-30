#!/usr/bin/env bash

### 进程控制模块 ###
function openFileDescriptor() {
  local file
  file=$(mktemp)
  local descript=${1:-1001}
  # 当出现INT时退出
  # shellcheck disable=SC2064
  trap "exec $descript>&-;exec $descript<&-;exit 1" 2
  mkfifo "$file" &>/dev/null
  sendLog "open file descriptor ${descript}" 0
  eval "exec $descript<>$file"
  rm -rf "$file"
}

function closeFileDescriptor() {
  local descript=${1:-1001}
  sendLog "close file descriptor ${descript}" 0
  eval "exec ${descript}<&-"
  eval "exec ${descript}>&-"

}

# 使用该方法不能set -x,进程控制数未生效待修复
function multiProcess() {
  local process function_name function_args a p descript=1001 err
  err=$(mktemp)
  function_name=$1
  shift 1
  function_args=$*
  process=${GLOBAL_PROCESS_NUM:-3}
  sendLog "Do multi process ,max is $process" 0
  openFileDescriptor $descript
  for ((p = 1; p <= "$process"; p++)); do
    echo ""
    sendLog "Process open $p " 0
  done >&${descript}
  # shellcheck disable=SC2034
  for a in ${function_args[*]}; do
    read -r -u${descript}
    {
      sendLog "Do function: ${function_name} with args: $a" 0
      "${function_name}" "$a" >/dev/null 2>>"${err}"
      echo "" >&$descript
    } &
  done
  wait
  closeFileDescriptor $descript
  if [[ -s "${err}" ]]; then
    sendLog "Some errors in doing  ${function_name}."
    sendLog "$(cat "${err}")" 3 n
    rm -rf "${err}"
    exit 1
  else
    rm -rf "${err}"
  fi
  sendLog "Do multi process end." 0
}

# 多并发执行用例
function multiTestFunctions() {
  local  max_process now_process function_name a err
  err=$(mktemp)
  function_name=$*
  max_process=${GLOBAL_PROCESS_NUM:-3}
  sendLog "Do multi process ,max is $max_process" 0
  now_process=0
  for a in ${function_name[*]}; do
    {
      sendLog "Do function: ${a}" 0
      if ! ${a} &>"${LOG_FILE}"; then
        # shellcheck disable=SC2028
        echo "Run ${a} error" >>"${err}"
      fi
    } &
    ((now_process++))
    if [ "$now_process" -ge "$max_process" ]; then
      wait -n
      ((now_process--))
    fi
  done
  wait
  if [[ -s "${err}" ]]; then
    sendLog "Some errors in doing functions: ${function_name[*]}."
    sendLog "$(cat "${err}")" 3 n
    rm -rf "${err}"
    return 1
  else
    rm -rf "${err}"
  fi
  sendLog "Do multi test functions ${function_name[*]} end." 0
  return 0

}
