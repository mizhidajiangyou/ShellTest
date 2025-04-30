#!/bin/bash
set -ex

source .env
# e.g. ./download.sh 1.tar test
# 配置参数
TARGET_DIR="${2:-test}/"            # MinIO中的目标目录（以/结尾）
FILE_PATH="${1:-1.tar}"         # 要下载的文件路径（相对于TARGET_DIR）


function download_minio() {
    # 配置MinIO别名（如果不存在）
    if ! mc alias list | grep -q "^${MINIO_ALIAS}\b"; then
        echo "正在配置MinIO连接..."
        mc alias set "$MINIO_ALIAS" "$MINIO_ENDPOINT" "$ACCESS_KEY" "$SECRET_KEY" --api s3v4
    fi

    # 构建完整MinIO路径
    MINIO_PATH="$MINIO_ALIAS/$BUCKET_NAME/$TARGET_DIR$FILE_PATH"

    # 检查文件是否存在
    echo "正在检查文件是否存在：$MINIO_PATH"
    if ! mc stat "$MINIO_PATH" &> /dev/null; then
        echo "错误：文件 $FILE_PATH 不存在于存储桶 $BUCKET_NAME/$TARGET_DIR 中" >&2
        exit 1
    fi

    # 下载文件到当前目录
    echo "开始下载文件到当前目录..."
    if ! mc cp --recursive "$MINIO_PATH" "./"; then
        echo "错误：文件下载失败" >&2
        exit 1
    fi
    echo "文件已成功下载到当前目录：$(pwd)/$FILE_PATH"

    # 删除远程文件
    echo "正在删除MinIO中的原始文件..."
    if ! mc rm --recursive --force "$MINIO_PATH"; then
        echo "警告：文件删除失败，请手动处理 $MINIO_PATH" >&2
        exit 1
    else
        echo "文件已成功从MinIO删除"
    fi


}

download_minio

