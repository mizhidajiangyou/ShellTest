#!/bin/bash

# 设置要删除的命名空间，默认是cattle-system
NS=${1:-cattle-system}

echo "准备强制删除命名空间: $NS"

# 检查命名空间是否存在
if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "命名空间 $NS 不存在，无需删除"
  exit 0
fi

# 尝试正常删除
#echo "尝试正常删除 $NS..."
#kubectl delete namespace "$NS"
#
## 等待30秒，检查是否删除成功
#sleep 30
if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "$NS 已成功删除"
  exit 0
fi

# 如果仍存在且处于Terminating状态，进行强制删除
echo "$NS 仍处于Terminating状态，准备强制删除..."

# 导出命名空间配置
kubectl get namespace "$NS" -o json > "$NS-temp.json"

# 删除finalizers字段
sed -i '/"finalizers": \[/,/\]/d' "$NS-temp.json"

# 通过API强制删除
kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f "$NS-temp.json"

# 清理临时文件
rm -f "$NS-temp.json"

# 检查结果
echo "强制删除操作已执行，检查结果..."
sleep 10
if kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "警告：$NS 可能仍未完全删除，请稍后再次检查"
else
  echo "$NS 已强制删除成功"
fi
