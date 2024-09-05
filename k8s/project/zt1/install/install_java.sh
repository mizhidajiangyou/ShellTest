#!/usr/bin/env bash

source scripts/common.sh

service_name="java"
# 基于：https://github.com/prometheus-community/helm-charts/releases/download/prometheus-20.0.2/prometheus-20.0.2.tgz

setKubeConfig

# yaml_create 创建yaml
# yaml_apply 依赖执行yaml_create后 kubectl apply
# helm_apply 执行helm install
# helm_upgrade 执行helm upgrade
# yaml_delete 依赖执行yaml_create后 kubectl delete
helm_mode=$1
helm_cmd="helm install"
yaml_dir=""
namespace="$(getImagesConf 'k8s' 'namespace')"

if [ -z "${namespace}" ]; then
  sendLog "namespace is null! please check images.cfg!" 3
  exit 1
fi

if [ "${helm_mode}" == "helm_upgrade" ]; then
  helm_cmd="helm_upgrade"
elif [ "${helm_mode}" == "yaml_create" ] || [ "${helm_mode}" == "yaml_apply" ]; then
  helm_cmd="helm template"
  yaml_dir="--output-dir yaml"
fi

sendLog "Do $helm_cmd $service_name ..." 1

if [ "${helm_mode}" == "yaml_apply" ]; then
  if [ ! -d yaml ]; then
    sendLog "please create yaml first !" 3
    exit 1
  fi
  yamlApply "$service_name" "${namespace}"
elif [ "${helm_mode}" == "yaml_delete" ]; then
  if [ ! -d yaml ]; then
    sendLog "please create yaml first !" 3
    exit 1
  fi
  yamlDelete "$service_name" "${namespace}"
else
  # 配置
  conf_cmd="\
  --set server.image.repository=$(getImagesPart $service_name 'image' 1) \
  --set server.image.tag=$(getImagesPart $service_name 'image' 2) \
  --set server.replicaCount=$(getImagesConf $service_name 'replica_count') \
  --set server.ingress.enabled=false \
  $service_name --namespace ${namespace} ${yaml_dir} artifact/$service_name"

  if eval "$helm_cmd $conf_cmd"; then
    sendLog "Do $helm_cmd $service_name successful!" 1 g
  else
    sendLog "Do $helm_cmd $service_name  failed!" 3
    exit 1
  fi
fi
