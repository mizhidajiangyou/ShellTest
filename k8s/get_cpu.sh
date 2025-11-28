#!/bin/bash
set -euo pipefail

# 获取所有命名空间
namespaces=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')

# 生成临时文件
TMP_REQUESTS=$(mktemp)
TMP_LIMITS=$(mktemp)

# 统计 requests（完全修复 jq 问题）
echo "统计 requests 资源（CPU 降序）..." >&2
for ns in $namespaces; do
  deployments=$(kubectl get deploy -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
  for dep in $deployments; do
    replicas=$(kubectl get deploy "$dep" -n "$ns" -o jsonpath='{.spec.replicas}' || echo "1")

    # 关键修复：jq 从 JSON 中提取 metadata.name 和 namespace
    kubectl get deploy "$dep" -n "$ns" -o json | jq -r --arg r "$replicas" '
      .spec.template.spec.containers[]? as $c |
      ($c.resources.requests.cpu // "0") as $cpu |
      ($c.resources.requests.memory // "0") as $mem |
      # CPU 转换：m → cores
      (if $cpu | endswith("m") then ($cpu | rtrimstr("m") | tonumber / 1000) else ($cpu | tonumber) end) as $cpu_cores |
      # 内存保留原始单位
      ($mem | if . == "0" then "0" else . end) as $mem_raw |
      ($cpu_cores * ($r | tonumber)) as $total_cpu |
      # 从 JSON 中提取 namespace 和 name
      .metadata.namespace as $ns |
      .metadata.name as $dep |
      "\($total_cpu) \($mem_raw) \($ns)/\($dep)"
    ' >> "$TMP_REQUESTS"
  done
done

# 统计 limits（同理修复）
echo "统计 limits 资源（CPU 降序）..." >&2
for ns in $namespaces; do
  deployments=$(kubectl get deploy -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
  for dep in $deployments; do
    replicas=$(kubectl get deploy "$dep" -n "$ns" -o jsonpath='{.spec.replicas}' || echo "1")

    kubectl get deploy "$dep" -n "$ns" -o json | jq -r --arg r "$replicas" '
      .spec.template.spec.containers[]? as $c |
      ($c.resources.limits.cpu // "0") as $cpu |
      ($c.resources.limits.memory // "0") as $mem |
      (if $cpu | endswith("m") then ($cpu | rtrimstr("m") | tonumber / 1000) else ($cpu | tonumber) end) as $cpu_cores |
      ($mem | if . == "0" then "0" else . end) as $mem_raw |
      ($cpu_cores * ($r | tonumber)) as $total_cpu |
      .metadata.namespace as $ns |
      .metadata.name as $dep |
      "\($total_cpu) \($mem_raw) \($ns)/\($dep)"
    ' >> "$TMP_LIMITS"
  done
done

# 输出结果（格式化 CPU 为 m 格式）
echo -e "\n\n✅ Requests 资源请求排名（CPU 降序，内存保留原始单位）："
echo "----------------------------------------"
sort -k1 -n -r "$TMP_REQUESTS" | awk '{
  cpu_m = int($1 * 1000) "m"
  printf "%-8s %-10s %s\n", cpu_m, $2, $3
}'

echo -e "\n\n✅ Limits 资源限制排名（CPU 降序，内存保留原始单位）："
echo "----------------------------------------"
sort -k1 -n -r "$TMP_LIMITS" | awk '{
  cpu_m = int($1 * 1000) "m"
  printf "%-8s %-10s %s\n", cpu_m, $2, $3
}'

rm -f "$TMP_REQUESTS" "$TMP_LIMITS"