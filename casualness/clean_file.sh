#!/usr/bin/env bash

file="/opt/test_*.log"

function check_usage() {
  local file check_usage usage
  # df -h | grep "$file" | awk '{sub(/%/, "", $5); if ($5 >= '"${useage}"') print "目录'"${file}"'空间使用率大于'"${useage}"': " $5"%"}'

  usage=$(df -h | grep "$file" | awk '{sub(/%/, "", $5); print $5}')

  if [ -n "$usage" ]; then
    if [ "$usage" -ge "${check_usage}" ]; then
      return 1
    else
      return 0
    fi
  else
    echo "无法获取磁盘使用率"
    return 1
  fi

}

function main() {
    if ! check_usage /opt 10 ;then
      echo error
    fi
}

main

# shellcheck disable=SC2140
# shellcheck disable=SC1012
file_list="ls -alt ${file} | awk '{size = $5 / (1024*1024*1024); printf "%sGB\t%s\n", size, $9}'"
