#!/bin/bash

min_version='4.0.0'
now_version=$(/bin/bash --version |head -n 1 |grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+")
small_version=$(echo -e "$now_version\n$min_version" | sort -V | head -n 1)
if [ "${small_version}" != "$min_version" ];then
  echo "当前使用的/bin/bash版本为$now_version,低于最低bash版本要求。"
  exit 1
fi

