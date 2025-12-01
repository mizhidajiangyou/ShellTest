#!/usr/bin/env bash

### k8s基础操作模块 ###

# 创建命名空间（存在则跳过，不重复创建）
function create_ns() {
    local ns="$1"
    if kubectl get ns "$ns" > /dev/null 2>&1; then
        sendLog "✅ Namespace '$ns' already exists. Skipping creation."
    else
        kubectl create ns "$ns" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            sendLog "Namespace '$ns' created successfully."
        else
            sendLog "❌ Failed to create namespace '$ns'. Check permissions or k8s status."
            exit 1
        fi
    fi
}

# 销毁命名空间（多次检测直到成功，超时60秒）
function delete_ns() {
    local ns="$1"
    sendLog "⏳ Deleting namespace '$ns'... (Waiting for cleanup)"
    if ! kubectl delete ns "$ns" &> /dev/null ; then
        sendLog "❌ Failed to initiate deletion for '$ns'."
        exit 1
    fi

    # 多次检测直到删除完成（最多60秒，每5秒检查一次）
    local max_wait=60
    local wait_interval=5
    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if ! kubectl get ns "$ns" > /dev/null 2>&1; then
            sendLog "✅ Namespace '$ns' deleted successfully."
            return 0
        fi
        sleep $wait_interval
        elapsed=$((elapsed + wait_interval))
    done
    sendLog "⏰ Timeout: Namespace '$ns' still exists after $max_wait seconds. Manual check needed!"
    exit 1
}


# 查看命名空间下的所有资源（包括Deployment, Pod, Service等）
function list_ns_resources() {
    local ns="$1"
    sendLog "🔍 Listing all resources in namespace '$ns':"
    kubectl get all -n "$ns" 2>/dev/null || sendLog "⚠️ Namespace '$ns' might not exist or has no resources."
}


function setKubeConfig() {
  if [ -n "${K8S_KUBECONFIG}" ]; then
    sendLog "used kubeconfig ${K8S_KUBECONFIG}" 0
    export KUBECONFIG="${K8S_KUBECONFIG}"
  fi
}

