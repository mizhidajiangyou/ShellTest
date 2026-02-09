#!/usr/bin/env bash

### 装饰器 ###
# 装饰器函数，实现加锁和解锁逻辑
function wLock() {
  local function_name="$1"
  shift

  # 获取锁
  flock -n 9 || {
    sendLog "Unable to acquire lock. Exiting." 2
    exit 1
  }

  # 执行被装饰的函数
  "$function_name" "$@"

  # 释放锁
  flock -u 9
}

# 轮训执行命令函数
# e.g. retry_exec "./start.sh -p 8080"
function retry_exec() {

    local exec_command="$*"
    local max_retries=${GLOBAL_MAX_RETRIES:-30}
    local retry_interval=${GLOBAL_RETRY_INTERVAL:-10}
    local current_retry=0

    sendLog "===== 开始轮训执行命令：${exec_command} =====" 0 &> /dev/null
    sendLog "最大轮训次数：${max_retries}，每次间隔：${retry_interval}秒" 0 &> /dev/null

    while [ ${current_retry} -lt "${max_retries}" ]; do
        current_retry=$((current_retry + 1))
        sendLog "[第 ${current_retry}/${max_retries} 次尝试] 执行命令：${exec_command}" 0 &> /dev/null

        if ! ${exec_command} &>> "${LOG_FILE:-shell.log}"; then
            sendLog "命令执行失败，等待 ${retry_interval} 秒后重试..." 0 &> /dev/null
            sleep "${retry_interval}"
        else
            sendLog "===== 命令执行成功！=====" 0 &> /dev/null
            return 0
        fi
    done

    # 4. 所有轮训次数用完仍失败
    sendLog "===== 错误：${exec_command} 轮训 ${max_retries} 次后，命令仍执行失败 =====" 3 &> /dev/null
    return 1
}
