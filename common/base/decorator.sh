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

