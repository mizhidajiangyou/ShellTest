#!/usr/bin/env bash

### 日志通知 ###
# 依赖字体模块
# 通用日志管理
function sendLog() {
  local LEVEL="INFO - "
  local COLOR=$3
  case $2 in
  0)
    if [ "${LOG_LEVEL}" == "debug" ]; then
      LEVEL="DEBUG - "
    else
      return
    fi
    ;;
  1)
    LEVEL="INFO - "
    ;;
  2)
    LEVEL="WARNING - "
    ;;
  3)
    LEVEL="ERROR - "
    COLOR=${COLOR:-r}
    ;;
  4)
    LEVEL="CRITICAL - "
    LOG_CONSOLE_PRINT="true"
    COLOR=${COLOR:-rg}
    ;;
  *)
    LEVEL="INFO - "
    ;;
  esac
  COLOR=$(enter_color "$COLOR")
  printf "%-25s%s\n" "$(date '+%Y-%m-%d %H:%M:%S.%3N')" " ${LEVEL}$1" >>"${LOG_FILE:-shell.log}"

  if ${LOG_CONSOLE_PRINT}; then
    printf "$COLOR%-25s%s${Z_COLOR_COLLECTION[none]}\n" "$(date '+%Y-%m-%d %H:%M:%S.%3N')" " ${LEVEL}$1"
  fi
}
