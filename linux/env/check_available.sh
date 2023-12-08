#!/bin/bash
# 目录最小容量
min=100
# 需要判断的目录
check_dir='/'

# 获取根目录的可用容量
available_space=$(df -h --output=avail $check_dir | tail -n 1)

# 提取数字部分
available_space_gb=$(echo "$available_space" | awk '{gsub("G","") ;print $1}')

# 检查容量是否小于100G
if (( available_space_gb < min )); then
    echo "失败：$check_dir 目录可用容量低于 $min G。当前可用容量为 $available_space_gb GB"
else
    echo "成功：$check_dir 目录可用容量为 $available_space_gb GB"
fi