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

setKubeConfig
