#!/usr/bin/env bash

### 结构管理模块 ###

# 初始化队列
function init_queue() {
  SHELL_QUEUE=()
}

# 入队
function enqueue() {
  SHELL_QUEUE=("${queue[@]}" "$1")
}

# 出队
function dequeue() {
  local dequeued
  if [ ${#SHELL_QUEUE[@]} -eq 0 ]; then
    sendLog "队列已空" 0 &>/dev/null
    return 1
  else
    dequeued=${SHELL_QUEUE[0]}
    SHELL_QUEUE=("${SHELL_QUEUE[@]:1}")
    sendLog "出队元素：$dequeued" 0 &>/dev/null
    echo "$dequeued"
    return 0
  fi
}

# 显示队列内容
function display_queue() {
  if [ ${#SHELL_QUEUE[@]} -eq 0 ]; then
    sendLog "队列为空" 0 &>/dev/null
    return 1
  else
    sendLog "队列内容：${SHELL_QUEUE[*]}" 0 &>/dev/null
    echo "${SHELL_QUEUE[*]}"
    return 0
  fi
}

# 并发执行队列中的函数
#e.g. SHELL_QUEUE=($(grep function "${file}" | awk '/case/{gsub(/\(\)/,"",$2); print $2}'))
function do_queue_function() {
  # 执行函数
  while display_queue &>/dev/null; do
    # shellcheck disable=SC2091
    $(dequeue) &
    dequeue
  done
  wait
}

init_queue
