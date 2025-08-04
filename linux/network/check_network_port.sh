#!/usr/bin/env bash

# 定义要检查的IP和端口列表
declare -A port_map=(
    ["192.168.0.1"]="22 80 8081 9090 9091"
)

# 检查telnet是否安装
if ! command -v telnet &> /dev/null; then
    echo "错误: telnet命令未找到，请先安装telnet"
    exit 1
fi

# 定义超时时间(秒)
# shellcheck disable=SC2034
TIMEOUT=5

# 循环检查每个IP和端口
for ip in "${!port_map[@]}"; do
    echo "====================================="
    echo "正在检查IP: $ip"
    echo "====================================="

    ports=${port_map[$ip]}
    for port in $ports; do
        # 使用telnet检查端口连通性，设置超时
        (echo > /dev/tcp/"$ip"/"$port") > /dev/null 2>&1
        result=$?

        if [ $result -eq 0 ]; then
            echo -e "端口 $port:\t\033[32m可用\033[0m"
        else
            echo -e "端口 $port:\t\033[31m不可用\033[0m"
        fi
    done
    echo ""
done

echo "检查完成"