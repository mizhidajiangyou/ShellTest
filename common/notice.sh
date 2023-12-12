#!/usr/bin/env bash

# 钉钉通知
function dingDing() {
  local mes=("$@")
  DingUrl="${DINGDING_URL}${DINGDING_TOKEN}"
  curl "$DingUrl" \
    -H 'Content-Type: application/json' \
    -d "{\"msgtype\": \"text\",\"at\":{\"atMobiles\":[${DINGDING_MOBILES}],\"isAtAll\": ""${DINGDING_ALL}""},\"text\": {\"content\":\"自动化通知：${mes[*]}\"}}"

}

# markdown模式的dingding通知
function dingDingMark() {
  local mes=("$@")
  DingUrl="${DINGDING_URL}${DINGDING_TOKEN}"
  curl "$DingUrl" \
    -H 'Content-Type: application/json' \
    -d "{\"msgtype\": \"markdown\",\"at\":{\"atMobiles\":[${DINGDING_MOBILES}],\"isAtAll\": ""${DINGDING_ALL}""},\"markdown\": {\"title\":\"report\",  \"text\":\"自动化通知：\n ${mes[*]}\"}}"

}

# 根据配置决定是否使用dingding,发送后退出
function useDing() {
  if "${DINGDING_USE}"; then
    dingDing "$1"
    exit 1
  fi
}