#!/usr/bin/env bash

### 时间管理模块 ###

function now_time_long() {
  date +%s%N
}

function now_time_short() {
  date +%s
}

function now_time_normal() {
  date '+%Y-%m-%d %H:%M:%S'
}

function now_time_big() {
  date '+%Y-%m-%d'
}

function now_time_sim() {
  date '+%Y%m%d%H%M%S'
}

function convert_timestamp() {
  date -d @$(($1 / 1000)) '+%Y-%m-%d'
}


function now_timestamp() {

    if date --version >/dev/null 2>&1; then
        date +%s%3N
    else
        date +%s%N | cut -c1-13
    fi
}


function h_later_timestamp() {
    local hour=${1:-24}
    # 先检测系统类型
    if date --version >/dev/null 2>&1; then
        date -d "$hour hour" +%s%3N
    else
        local minutes=$(( $(echo "$hour * 60" | bc) ))
        date -v "+${minutes}M" +%s%N | cut -c1-13
    fi
}

function convert_timestamp_long() {
  date -d @"$1" -u "+%Y-%m-%dT%H:%M:%S.%3NZ"
}

function now_date_long() {
  date  "+%Y-%m-%dT%H:%M:%S.%3NZ"
}

# 时间戳转换为日期函数
function timestamp_to_date() {
    local timestamp=$1
    # shellcheck disable=SC2004
    date -d @$(($timestamp/1000)) "+%Y-%m-%d"
}


