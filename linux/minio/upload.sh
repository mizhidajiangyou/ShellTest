#!/usr/bin/env bash

# e.g. ./upload.sh 1.tar test

source .env

# 配置 MinIO 连接信息（需替换为实际值）
TARGET_DIR="${2:-test}/"            # 目标目录（以 / 结尾）
FILE_PATH="${1:-1.tar}"         # 要上传的文件路径

# 检查文件是否存在
if [ ! -f "$FILE_PATH" ]; then
    echo "错误：文件 $FILE_PATH 不存在！"
    exit 1
fi

# 配置 MinIO 别名（如果未配置）
if ! mc alias list | grep -q "$MINIO_ALIAS"; then
    echo "配置 MinIO 别名..."
    mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY"
fi

# 确保存储桶存在（如果不存在则创建）
echo "检查存储桶 $BUCKET_NAME..."
if ! mc ls "$MINIO_ALIAS" | grep -q "$BUCKET_NAME"; then
    echo "创建存储桶 $BUCKET_NAME..."
    mc mb "$MINIO_ALIAS/$BUCKET_NAME"
fi

# 上传文件到指定目录
echo "上传文件 $FILE_PATH 到 $MINIO_ALIAS/$BUCKET_NAME/$$TARGET_DIR"

# 验证上传结果
if mc cp "$FILE_PATH" "$MINIO_ALIAS/$BUCKET_NAME/$TARGET_DIR"; then
    echo "文件上传成功！"
    echo "验证文件是否存在"
    if  mc ls "$MINIO_ALIAS/$BUCKET_NAME/$TARGET_DIR" | grep -q "$(basename $FILE_PATH)"; then
        echo "验证通过：文件存在于目标路径:$MINIO_ALIAS/$BUCKET_NAME/$TARGET_DIR"
    else
        echo "警告：文件未出现在目标路径:$MINIO_ALIAS/$BUCKET_NAME/$TARGET_DIR !"
        exit 1
    fi
else
    echo "错误：文件上传失败！"
    exit 1
fi


