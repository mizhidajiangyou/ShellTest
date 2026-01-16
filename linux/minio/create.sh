#!/bin/bash

# 安装 mc 命令（如果尚未安装）
if ! command -v mc &> /dev/null; then
    echo "mc 命令未安装，正在安装..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc
    chmod +x mc
    sudo mv mc /usr/local/bin/
fi

# 设置 MinIO 凭证
export MINIO_ROOT_USER="123321"
export MINIO_ROOT_PASSWORD="456654"

# 配置 mc 客户端
echo "配置 MinIO 服务器连接..."
mc alias set myminio http://123321:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# 检查连接是否成功
if mc admin info myminio; then
    echo "成功连接到 MinIO 服务器"

    # 创建 bucket
    BUCKET_NAME="456654"
    echo "正在创建 bucket: $BUCKET_NAME"

    if mc mb myminio/$BUCKET_NAME; then
        echo "成功创建 bucket: $BUCKET_NAME"

        # 验证 bucket 是否创建成功
        echo "验证 bucket 创建结果:"
        mc ls myminio | grep $BUCKET_NAME
    else
        echo "创建 bucket 失败，请检查权限和连接状态"
        exit 1
    fi
else
    echo "连接 MinIO 服务器失败，请检查网络连接和凭证信息"
    exit 1
fi

echo "操作完成！"