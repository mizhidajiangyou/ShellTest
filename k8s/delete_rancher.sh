#!/bin/bash
# 用于强制删除 Rancher 顽固命名空间

# 需要删除的命名空间（显式指定，避免误删）
ns_list=("cattle-system" "cattle-impersonation-system")

echo "开始强制删除以下命名空间: ${ns_list[@]}"
echo "==============================================="

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo "错误: 未找到 jq 命令。请先安装 jq:"
    echo "  CentOS/RHEL: sudo yum install -y jq"
    echo "  Ubuntu/Debian: sudo apt-get install -y jq"
    exit 1
fi

# 开启本地代理
echo "启动 kubectl proxy..."
kubectl proxy > /dev/null 2>&1 &
proxy_pid=$!
sleep 2  # 等待 proxy 启动

# 检查 proxy 是否成功启动
if ! kill -0 $proxy_pid 2>/dev/null; then
    echo "错误: kubectl proxy 启动失败"
    exit 1
fi

echo "kubectl proxy 已启动 (PID: $proxy_pid)"

# 执行删除
for ns in "${ns_list[@]}"; do
    echo "-----------------------------------------------"
    echo "处理命名空间: $ns"

    # 检查命名空间是否存在
    if ! kubectl get ns "$ns" > /dev/null 2>&1; then
        echo "警告: 命名空间 $ns 不存在，跳过"
        continue
    fi

    echo "1. 获取命名空间配置..."
    kubectl get ns "$ns" -o json > "$ns.json"

    echo "2. 移除 finalizers 和 spec 配置..."
    # 移除所有 finalizers 并清空 spec
    cat "$ns.json" | jq '.metadata.finalizers = [] | .spec = {}' > "$ns"-patched.json

    echo "3. 应用修改..."
    response=$(curl -s -k -H "Content-Type: application/json" \
        -X PUT \
        --data-binary @"$ns"-patched.json \
        http://127.0.0.1:8001/api/v1/namespaces/"$ns"/finalize)

    # 检查响应
    if echo "$response" | jq -e '.status.phase' > /dev/null 2>&1; then
        phase=$(echo "$response" | jq -r '.status.phase')
        echo "4. 命名空间 $ns 状态: $phase"
    else
        echo "4. API 响应:"
        echo "$response" | jq .
    fi

    # 清理临时文件
    rm -f "$ns.json" "$ns"-patched.json
done

echo "==============================================="
echo "5. 检查最终状态..."
kubectl get ns | grep -E "(NAME|Terminating|cattle)"

# 清理 proxy
echo "6. 停止 kubectl proxy (PID: $proxy_pid)..."
kill $proxy_pid
wait $proxy_pid 2>/dev/null

echo "==============================================="
echo "完成! 如果命名空间仍然处于 Terminating 状态，"
echo "请尝试重启 kubelet 服务或联系 Kubernetes 管理员。"