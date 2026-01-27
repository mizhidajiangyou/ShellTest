#!/usr/bin/env bash

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function setKubeConfig() {
  local conf
  conf="$(configParser "k8s" "kubeconfig" "images.cfg")"
  if [ -n "${conf}" ]; then
    export KUBECONFIG="${conf}"
  fi
}

function setNodeIP() {
  local node_ip
  if [ "$(getImagesConf k8s custom_node_ip)" != "true" ];then
    node_ip=$(kubectl get nodes -o wide | awk '/Ready/{print $6}' | head -n 1)
    configParser k8s node_ip images.cfg "$node_ip"
  fi
}

function getImagesConf() {
  local section=$1
  local value=$2
  configParser "${section}" "${value}" "images.cfg"

}

function getServicePrefix() {
    configParser "global" "prefix" "images.cfg"
}

function getImagesPart() {
  local section=$1
  local value=$2
  local part=$3
  local img
  img=$(configParser "${section}" "${value}" "images.cfg")
  if [ "$part" == "1" ]; then
    echo "$img" | awk -F: '{print $1}'
  elif [ "$part" == "2" ]; then
    echo "$img" | awk -F: '{print $2}'
  else
    echo "$img"
  fi
}

function yamlApply() {
  local service=$1 yaml namespace=$2
  sendLog "yaml apply files in ${namespace}"
  for yaml in yaml/"$service"/templates/*.yaml; do
    [[ -e $yaml ]] || break
    if ! kubectl apply -f "$yaml" -n "${namespace}"; then
      sendLog "kubectl apply $service with yaml failed"
      exit 1
    fi
  done
  sendLog "kubectl apply $service with yaml successful!" 1 g

}

function yamlDelete() {
  local service=$1 yaml stats=0 namespace=$2
  if [ ! -d yaml/"$service"/templates ]; then
    sendLog "no such file : yaml/$service/templates" 3
    exit 1
  fi
  for yaml in yaml/"$service"/templates/*.yaml; do
    [[ -e $yaml ]] || break
    if [[ "${yaml##*/}" == *"pvc.yaml"* ]]; then
      sendLog "pvc 文件暂时不删除" 0
    else
      if ! kubectl delete -f "$yaml" -n "${namespace}" ; then
        sendLog "删除yaml: ${yaml} 失败" 3
        stats=1
      fi
      # sendLog "delete $yaml" 0
    fi
  done
  if [ $stats -eq 0 ]; then
    sendLog "kubectl delete $service with yaml successful!" 1 g
  else
    sendLog "删除yaml存在失败！请检查。" 3 y
  fi
}

function pvcDelete() {
  local service_list ns i all=$1
  service_list=$(configParser install service images.cfg)
  ns=$(configParser k8s namespace images.cfg)
  if [ -n "$all" ]; then
    sendLog "Delete all pvc in namespace ${ns},check in 3s" 3
    countdown 3
    kubectl get pvc -n "${ns}" | awk '{print $1}' | xargs -L 1 -I {} kubectl delete pvc -n "${ns}" {}
    sendLog "Delete all pvc successful." 1 g
    return 0
  fi
  for i in "${service_list[@]}"; do
    if kubectl get pvc -n "$ns" 2>&1 | grep "No resources found" &>/dev/null; then
      sendLog "No service $i pvc,skip!"
      break
    fi
    kubectl get pvc -n "${ns}" | grep "${i}" | awk '{print $1}' | xargs -L 1 -I {} kubectl delete pvc -n "${ns}" {}
    sendLog "Delete ${i} pvc successful." 0 g
  done

}


# 返回预期的pod-就绪的pod
function check_service_num() {
  local service=${1:base-server} namespace
  namespace="$(getImagesConf 'k8s' 'namespace')"
  kubectl get pods -n "${namespace}" | grep "${service}" | grep Running | awk -v num="$(getImagesConf "$service" replica_count)" '
  BEGIN { sum_left=0; sum_right=0 }
  {
      split($2, arr, "/");
      sum_left += arr[1];
      sum_right += arr[2]
  }
  END {
      if (sum_left == sum_right && sum_left == num) {
          print "true"
      } else {
          print  num - sum_left
      }
  }'
}

function check_service_health() {
  local service=${1:base-server} retry_count result=0
  MAX_RETRIES=$(configParser "global" "retry_num" global.cfg)
  RETRY_INTERVAL=$(configParser "global" "sleep_time" global.cfg)

  retry_count=0
  if [ -z "$service" ]; then
      sendLog "错误：未设置service变量" 3
      exit 1
  fi
  sendLog "即将校验${service} 部署状态是否正常。"
  while [ $retry_count -lt "$MAX_RETRIES" ]; do

    result=$(check_service_num "${service}")
    if [ "$result" = "true" ]; then
      sendLog "${service}状态正常" 1 g
      return 0
    fi

    # 未成功，输出当前结果并等待重试
    sendLog "第 $((retry_count + 1)) 次检查${service}是否就绪未通过，存在${result}个服务未就绪，将在 $RETRY_INTERVAL 秒后重试" 1
    retry_count=$((retry_count + 1))

    if [ $retry_count -lt "$MAX_RETRIES" ]; then
      sleep "$RETRY_INTERVAL"
    fi
  done

  sendLog "达到最大重试次数 ($MAX_RETRIES 次)，服务${service}检查未通过" 3
  exit 1

}


function writeK8sUsefulSH() {
  local write_path=${1:-artifact}
  sendLog "start to make ${write_path} k8s scripts"
  pushd "${write_path}" || exit 1
  writeK8sStart
  writeK8sStop
  writeK8sRestart
  writeK8sUpdate
  writeK8sLog
  writeK8sDescribe
  writeK8sResources
  popd || exit 1
  sendLog "make ${write_path} k8s scripts end"
}

function writeK8sStart() {
  if [ ! -f start.sh ]; then
    sendLog "write start.sh" 0
    cat >start.sh <<EOF
#!/bin/bash


helm install $(basename "$(pwd)") . --namespace "$(configParser "k8s" "namespace" "images.cfg" )" --create-namespace
EOF
    chmod +x start.sh
  fi
}

function writeK8sStop() {
  if [ ! -f stop.sh ]; then
    sendLog "write stop.sh" 0
    cat >stop.sh <<EOF
#!/bin/bash

helm delete $(basename "$(pwd)") --namespace "$(configParser "k8s" "namespace" "images.cfg" )"
EOF
    chmod +x stop.sh
  fi
}

function writeK8sRestart() {
  if [ ! -f restart.sh ]; then
    sendLog "write restart.sh" 0
    cat >restart.sh <<EOF
#!/bin/bash

helm rollback $(basename "$(pwd)") 0 --namespace "$(configParser "k8s" "namespace" "images.cfg" )"
EOF
    chmod +x restart.sh
  fi
}

function writeK8sUpdate() {
  if [ ! -f update.sh ]; then
    sendLog "write update.sh" 0
    cat >update.sh <<EOF
#!/bin/bash

helm upgrade $(basename "$(pwd)") . --namespace "$(configParser "k8s" "namespace" "images.cfg" )"
EOF
    chmod +x update.sh
  fi
}

function writeK8sLog() {
  if [ ! -f log.sh ]; then
    sendLog "write log.sh" 0
    cat >log.sh <<EOF
#!/bin/bash

# 获取pod名称
POD_NAME=\$(kubectl get pods -n "$(configParser "k8s" "namespace" "images.cfg" )" -l app.kubernetes.io/instance="$(basename "$(pwd)")" -o jsonpath='{.items[0].metadata.name}')

if [ -n "\$POD_NAME" ]; then
  kubectl logs -f "\$POD_NAME" --namespace "$(configParser "k8s" "namespace" "images.cfg" )"
else
  echo "No pod found for release $(basename "$(pwd)")"
fi
EOF
    chmod +x log.sh
  fi
}

function writeK8sDescribe() {
  if [ ! -f describe.sh ]; then
    sendLog "write describe.sh" 0
    cat >describe.sh <<EOF
#!/bin/bash

# 获取pod名称
POD_NAME=\$(kubectl get pods -n "$(configParser "k8s" "namespace" "images.cfg" )" -l app.kubernetes.io/instance="$(basename "$(pwd)")" -o jsonpath='{.items[0].metadata.name}')

if [ -n "\$POD_NAME" ]; then
  kubectl describe pod "\$POD_NAME" --namespace "$(configParser "k8s" "namespace" "images.cfg" )"
else
  echo "No pod found for release $(basename "$(pwd)")"
fi
EOF
    chmod +x describe.sh
  fi
}

function writeK8sResources() {
  if [ ! -f resources.sh ]; then
    sendLog "write resources.sh" 0
    cat >resources.sh <<EOF
#!/bin/bash

echo "=== Resources for release $RELEASE_NAME ==="
echo "\n--- All Resources (using label selector) ---"
kubectl get all -n "$(configParser "k8s" "namespace" "images.cfg" )" -l app.kubernetes.io/instance=$(basename "$(pwd)")

EOF
    chmod +x resources.sh
  fi
}



setKubeConfig
