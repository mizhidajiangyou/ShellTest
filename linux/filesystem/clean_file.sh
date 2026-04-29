#!/bin/bash
set -euo pipefail  # 强化错误检测：未定义变量报错、管道失败报错、命令失败退出
#set -x

# ===================== 配置项（提前定义，避免作用域问题）=====================
# 目录最小容量(GB)，第二个参数，默认50
min=${2:-50}
# 需要判断的目录，第一个参数，默认/
check_dir=${1:-/}


# ===================== 核心函数 =====================
# 钉钉通知函数
function dingDing() {
  local mes="$*"  # 改为字符串（数组传参易出问题）
  # 修复JSON格式：布尔值不加引号，引号嵌套正确
  local post_data=$(cat <<EOF
{
  "msgtype": "text",
  "at": {
    "atMobiles": ["${DINGDING_MOBILES}"],
    "isAtAll": ${DINGDING_ALL}
  },
  "text": {
    "content": "自动化通知：${mes}"
  }
}
EOF
  )

  # 发送钉钉消息，添加容错和日志
  curl -s -X POST "$DING_URL" \
    -H 'Content-Type: application/json' \
    -d "$post_data" || echo "⚠️ 钉钉通知发送失败"
}

# 获取目录可用容量（GB，处理浮点数，统一单位）
function get_available_gb() {
  local dir=$1
  # df输出：先转成KB（统一单位），再转GB，避免M/G单位问题
  local available_kb=$(df --block-size=K --output=avail "$dir" | tail -n 1 | tr -d 'K')
  # 转GB（1GB=1024KB*1024=1048576KB），保留1位小数
  echo "scale=1; $available_kb / 1048576" | bc
}

# 获取本机IP（替代ifconfig，兼容无ifconfig的系统）
function get_local_ip() {
  # 提取第一个非回环、UP状态的网卡的IP(v4)
  ip a | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | grep -v 'docker' | head -n1 | awk '{print $2}' | cut -d'/' -f1
}

# ===================== 主逻辑 =====================
# 获取当前可用容量（GB）
available_space_gb=$(get_available_gb "$check_dir")
# 浮点数比较：用bc命令替代((...))（((不支持浮点数）
if (( $(echo "$available_space_gb < $min" | bc -l) )); then
  # 1. 定义清理记录变量
  cleaned_files=""
  cleaned_images=""

  # 2. 清理指定目录下的.tar文件（修复路径：从check_dir找，不是当前目录）
  echo "🔍 查找$check_dir下的.tar文件..."
  # 用数组存储文件，避免文件名含空格分割错误
  mapfile -t tar_files < <(find "$check_dir" -maxdepth 1 -type f -name "*.tar" 2>/dev/null)
  if [ ${#tar_files[@]} -gt 0 ]; then
    for tar_file in "${tar_files[@]}"; do
      echo "🗑️ 删除文件：$tar_file"
      rm -rf "$tar_file" && cleaned_files+="$tar_file " || echo "⚠️ 删除失败：$tar_file"
    done
  else
    cleaned_files="无"
  fi

  # 3. 清理docker虚悬镜像（修复筛选方式：用官方筛选参数，更精准）
  echo "🔍 查找docker虚悬镜像..."
  mapfile -t none_images < <(docker images -f "dangling=true" -q 2>/dev/null)
  if [ ${#none_images[@]} -gt 0 ]; then
    for img_id in "${none_images[@]}"; do
      echo "🗑️ 删除镜像：$img_id"
      # 加容错：镜像被占用时不中断脚本
      docker rmi -f "$img_id" && cleaned_images+="$img_id " || echo "⚠️ 删除失败：$img_id"
    done
  else
    cleaned_images="无"
  fi

  # 4. 获取清理后的容量
  available_space_gb2=$(get_available_gb "$check_dir")
  # 获取本机IP
  local_ip=$(get_local_ip)

  # 5. 发送钉钉通知（修复换行符，适配JSON格式）
  notify_msg="环境${local_ip:-未知IP},容量不足：
  - 检查目录：$check_dir
  - 阈值容量：$min GB
  - 清理前容量：$available_space_gb GB
  - 清理文件：${cleaned_files}
  - 清理镜像：${cleaned_images}
  - 清理后容量：$available_space_gb2 GB"
  # 替换换行符为钉钉支持的\n
  notify_msg=$(echo "$notify_msg" | sed ':a;N;$!ba;s/\n/\\n/g')
  dingDing "$notify_msg"

  # 6. 输出日志
  echo "❌ 容量不足：$check_dir 目录可用容量低于 $min G。清理后容量为 $available_space_gb2 GB"
else
  echo "✅ $check_dir 目录可用容量为 $available_space_gb GB（≥ $min GB），无需清理"
fi