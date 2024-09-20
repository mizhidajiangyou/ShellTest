#!/usr/bin/env bash

### 信号处理 ###

function trap_c() {
  if [ -z "$1" ]; then
    trap "print_color 'end in Ctrl c' r" INT
  else
    trap - INT
  fi
}
