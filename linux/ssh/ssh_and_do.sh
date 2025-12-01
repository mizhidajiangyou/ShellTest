#!/bin/bash

# 检查入参是否存在
if [ $# -eq 0 ]; then
    echo "错误：请传入需要执行的Linux命令作为参数！"
    echo "示例：./run_cmd_on_servers.sh \"yum install python3 -y\""
    exit 1
fi

# 配置信息
MAX_TIMEOUT=300
ROOT_USER="root"
ROOT_PASS="234"  # 确保与实际root密码一致
CMD="$*"  # 接收传入的命令（支持带空格）
SERVERS=(
    "192.168.0.1"
    "192.168.0.2"
)

# 检查expect是否安装
if ! command -v expect &> /dev/null; then
    echo "错误：未安装expect工具，请先安装："
    echo "CentOS/RHEL: sudo yum install expect -y"
    echo "Debian/Ubuntu: sudo apt install expect -y"
    exit 1
fi

# 循环执行命令
for server in "${SERVERS[@]}"; do
    echo "====================================="
    echo "在服务器 $server 执行命令：$CMD"
    echo "-------------------------------------"

    # expect脚本（移除行内注释，避免语法错误）
    expect -c "
        spawn ssh -o StrictHostKeyChecking=no $ROOT_USER@$server
        set timeout $MAX_TIMEOUT

        expect {

            \"*password:*\" {
                send \"$ROOT_PASS\r\"
                exp_continue
            }

            \"$ROOT_USER@*\" {
                send \"$CMD; echo 'CMD_FINISHED'\r\"
                expect \"CMD_FINISHED\"

                send \"exit\r\"
                expect eof
            }

            timeout {
                puts \"\n$server: 命令执行超时（超过$MAX_TIMEOUT秒）\"
                exit 1
            }
            eof { exit 0 }
        }
    "

    echo "-------------------------------------"
    echo "服务器 $server 执行完毕"
    echo "====================================="
    echo
done

echo "所有服务器命令执行完成！"