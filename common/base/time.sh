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

function now_time_sim() {
    date '+%Y%m%d%H%M%S'
}

