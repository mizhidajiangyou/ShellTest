#!/usr/bin/expect -f

# 配置参数
set USER "mzdjy"                ;# 登录用户名
set USER_PASSWORD "mzdjy"      ;# 用户密码
set NEW_ROOT_PASSWORD "mzdjy@123" ;# 新的root密码
set SSH_KEY "ssh-rsa test@zz"

# 服务器列表
set SERVER_LIST {
    "192.168.0.1"
}

# 设置超时时间
set timeout 30

# 循环处理每台服务器
foreach server $SERVER_LIST {
    puts "\n=================================================="
    puts "开始处理服务器: $server"

    # 启动ssh连接
    spawn ssh $USER@$server

    expect {
        # 处理首次连接的确认
        "Are you sure you want to continue connecting (yes/no)?" {
            send "yes\r"
            exp_continue
        }
        # 处理用户密码提示
        "password:" {
            send "$USER_PASSWORD\r"
        }
        # 处理可能的错误
        "Permission denied" {
            puts "服务器 $server 登录失败，密码可能不正确"
            continue
        }
        timeout {
            puts "服务器 $server 连接超时"
            continue
        }
    }

    # 等待登录成功，出现命令提示符
    expect "$ "

    # 通过sudo获取root权限
    puts "获取root权限..."
    send "sudo -s\r"

    expect {
        # 处理sudo密码提示
        "password for $USER:" {
            send "$USER_PASSWORD\r"
            exp_continue
        }
        # 处理可能的sudo警告信息
        "WARNING" {
            exp_continue
        }
        # 等待root命令提示符
        "#"
    }

    # 修改root密码
    puts "正在修改 $server 的root密码..."
    send "echo -e \"$NEW_ROOT_PASSWORD\n$NEW_ROOT_PASSWORD\" | passwd root\r"
    expect "#"

    # 确保.ssh目录存在并设置正确权限
    puts "正在配置 $server 的SSH密钥..."
    send "mkdir -p ~/.ssh && chmod 700 ~/.ssh\r"
    expect "#"

    # 写入公钥到authorized_keys并设置权限
    send "echo \"$SSH_KEY\" >> ~/.ssh/authorized_keys\r"
    expect "#"
    send "chmod 600 ~/.ssh/authorized_keys\r"
    expect "#"

    # 退出root权限
    send "exit\r"
    expect "$ "

    # 退出SSH连接
    send "exit\r"
    expect eof

    puts "服务器 $server 配置完成"
    puts "==================================================\n"
}

puts "所有服务器处理完毕"
