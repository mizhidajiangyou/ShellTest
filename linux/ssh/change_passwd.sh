#!/bin/bash

# 配置信息
USER="test"               # 登录用户名
PASS="123"             # 登录密码
NEW_ROOT_PASS="234"    # 新的 root 密码
# 服务器列表
SERVERS=(
    "192.168.0.1"
    "192.168.0.2"
)

# 检查 expect 是否安装
if ! command -v expect &> /dev/null; then
    echo "错误：未安装 expect 工具，请先执行以下命令安装："
    echo "sudo yum install expect -y （CentOS/RHEL）"
    echo "sudo apt install expect -y （Debian/Ubuntu）"
    exit 1
fi

# 循环处理每个服务器
for server in "${SERVERS[@]}"; do
    echo "====================================="
    echo "开始处理服务器：$server"

    # 使用 expect 自动登录并执行命令
    expect -c "
        spawn ssh -o StrictHostKeyChecking=no $USER@$server
        expect {
            \"*password:*\" { send \"$PASS\r\"; exp_continue }
            \"$USER@*\" {
                # 切换到 root（假设 hyperchain 有 sudo 权限，输入自身密码）
                send \"sudo su -\r\"
                expect {
                    \"*password for $USER:*\" { send \"$PASS\r\"; exp_continue }
                    \"root@*\" {
                        # 修改 root 密码
                        send \"passwd root\r\"
                        expect \"New password:\"
                        send \"$NEW_ROOT_PASS\r\"
                        expect \"Retype new password:\"
                        send \"$NEW_ROOT_PASS\r\"
                        expect {
                            \"*successfully*\" { puts \"$server: root 密码修改成功\"; }
                            default { puts \"$server: 密码修改失败\"; }
                        }
                        # 退出 root 和 ssh 连接
                        send \"exit\r\"
                        send \"exit\r\"
                    }
                }
            }
            timeout { puts \"$server: 连接超时\"; exit 1 }
            eof { exit 0 }
        }
    "

    echo "$server 处理完成"
    echo "====================================="
    echo
done

echo "所有服务器处理完毕，请手动验证密码是否生效。"