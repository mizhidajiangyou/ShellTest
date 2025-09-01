#!/usr/bin/env bash

source scripts/common.sh

function check_command_ok() {
  checkCommand "jq"
  checkCommand "nc"
  checkCommand "kubectl"
  checkCommand "helm"
  checkCommand "ifconfig"
}

# 检查metrics Server是否安装
function check_metrics_server() {
  # 检查metrics-server pod 是否存在
  if kubectl get pods -A | grep "metrics-server" >/dev/null 2>&1; then
    # 检查是否能获取节点的资源使用情况
    if kubectl top node >/dev/null 2>&1; then
      print_green "Metrics Server 已经安装"
    else
      print_red "Metrics Server 已经安装，但无法获取节点的资源使用情况"
      exit 1
    fi
  else
    print_red "Metrics Server 没有安装"
    exit 1
  fi
}

# 校验k8s基础服务是否正常
function check_k8s() {
  local namespace storage_class
  # 校验是否有可用的node
  if ! kubectl get node -owide | grep -q Ready; then
    sendLog "没有Ready的k8s node!" 3
    kubectl get node -owide
    exit 1
  else
    sendLog "检测存在可调度的k8s node" 0 g
  fi

  # 检查Namespace
  namespace=$(configParser "k8s" "namespace" "images.cfg")
  if ! kubectl get ns ${namespace} | grep -q Active; then
    sendLog "namespace ${namespace} 非Active!" 3
    exit 1
  else
    sendLog "检测 namespace ${namespace} Active" 0 g
  fi

  storage_class=$(configParser "k8s" "storage_class" "images.cfg")
  # 检查storageclass是否存在
  if ! kubectl get sc "${storage_class}" &>/dev/null; then
    sendLog "检测 storageclass ${storage_class} 不存在" 3
    exit 1
  else
    sendLog "检测 storageclass ${storage_class} 存在" 0 g
  fi

  # 校验metric service
  if ! kubectl get pods -A | grep metrics-server | grep -q Running; then
    sendLog "检测 Metrics Server 不存在" 3
    exit 1
  else
    sendLog "检测 Metrics Server 存在" 0 g
  fi

  if ! kubectl top node &>/dev/null; then
    sendLog "检测 kubectl top node 执行异常" 3
    exit 1
  else
    sendLog "检测 kubectl top node  正常" 0 g
  fi

}

# 测试当前端口输入是否已经被K8s占用
function check_equal_k8s_nodeport() {
  local match=0
  for np in "${USED_NODE_PORT[@]}"; do
    if [[ $np = "$1" ]]; then
      match=1
      break
    fi
  done
  echo ${match}
}

function recommend_port_can_use {
  local count max_count is_valid i
  # 设置计数器和最大数量(10个)
  count=0
  max_count=5
  echo "推荐尝试使用如下端口"
  # 遍历30000到32767的整数
  for ((i = 32000; i <= 32767 && count < max_count; i++)); do
    # 检查当前数字是否在数组内
    if [[ "${USED_NODE_PORT[*]}" != *"$i"* ]]; then
      # 数字不在数组中，将其打印到控制台
      is_valid=1
      # 检查grocNodePort端口是否被占用
      for node in "${NODE_HOST_ARRAY[@]}"; do
        if [[ $node != "" ]]; then
          nc_result=$(check_port_open_or_close "$node" "$i")
          if [ "$nc_result" == "0" ]; then
            is_valid=0
          fi
        fi
      done
      if [[ ${is_valid} == 1 ]]; then
        echo "$i"
        count=$((count + 1))

      fi
    fi
  done
}

function check_nodeport_host() {
  local now_check_port=$1
  if [[ ${now_check_port} -gt 32767 ]] || [[ ${now_check_port} -lt 30000 ]]; then
    sendLog "NodePort 默认范围30000-32767, You Input ${now_check_port} Invalid" 3
    exit 1
  fi
  # 检查端口是否已经被K8s分配
  for port in "${ALLOCATED_NODE_PORT_ARRAY[@]}"; do
    if [[ ${now_check_port} == "$port" ]]; then
      sendLog "NodePort端口 ${now_check_port} 被占用" 3
      recommend_port_can_use
      exit 1
    fi
  done
  # 检查grocNodePort端口是否被占用
  for node in "${NODE_HOST_ARRAY[@]}"; do
    if [[ $node != "" ]]; then
      nc_result=$(check_port_open_or_close "$node" "${now_check_port}")
      if [ "$nc_result" == "0" ]; then
        sendLog "NodePort端口 ${now_check_port} 被占用" 3
        recommend_port_can_use
        exit 1
      fi
    fi
  done
  sendLog "NodePort端口 $1 没有被占用" 0 g

}

function check_node_port_in_images() {
  local check_node_port_list p
  check_node_port_list=$(grep node_port images.cfg | awk -F= '{print $2}')
  for p in ${check_node_port_list[*]}; do
    sendLog "check port : $p in images" 0
    check_nodeport_host "$p"
  done
}

function main() {

  check_command_ok
  check_k8s
  USED_NODE_PORT="$(kubectl get svc --all-namespaces -o \
    go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}')"
  ALLOCATED_NODE_PORT_STRING="$(kubectl get svc --all-namespaces -o \
  go-template='{{range .items}}{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{","}}{{end}}{{end}}{{end}}')"
  # shellcheck disable=SC2207
  # shellcheck disable=SC2001
  ALLOCATED_NODE_PORT_ARRAY=($(echo "$ALLOCATED_NODE_PORT_STRING" | sed 's/,/\n/g'))
  check_node_port_in_images
}

setKubeConfig
main
