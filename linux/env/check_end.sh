#!/bin/bash
# 目录最小容量
min=100

# 获取根目录的可用容量（以人类可读的格式）
available_space=$(df -h --output=avail / | tail -n 1)

# 提取数字部分
available_space_gb=$(echo "$available_space" | awk '{gsub("G","") ;print $1}')

# 检查容量是否小于100G
if (( available_space_gb < min )); then
    echo "失败：根目录可用容量低于 $min G。当前可用容量为 $available_space_gb GB"
else
    echo "成功：根目录可用容量为 $available_space_gb GB"
fi