#!/usr/bin/env bash

source scripts/common.sh

service_name="prometheus"
# 基于：https://github.com/prometheus-community/helm-charts/releases/download/prometheus-20.0.2/prometheus-20.0.2.tgz

setKubeConfig

# yaml_create 创建yaml
# yaml_apply 创建yaml 后 kubectl apply
# helm_apply 执行helm install
# helm_upgrade 执行helm upgrade
helm_mode=$1
helm_cmd="helm install"
yaml_dir=""

if [ "${helm_mode}" == "helm_upgrade" ]; then
  helm_cmd="helm_upgrade"
elif [ "${helm_mode}" == "yaml_create" ] || [ "${helm_mode}" == "yaml_apply" ]; then
  helm_cmd="helm template"
  yaml_dir="--output-dir yaml"
fi

sendLog "Do $helm_cmd $service_name ..." 1
# 配置
conf_cmd="\
--set server.image.repository=$(getImagesPart 'prometheus' 'image' 1) \
--set server.image.tag=$(getImagesPart 'prometheus' 'image' 2) \
--set server.replicaCount=$(getImagesConf 'prometheus' 'replica_count') \
--set server.ingress.enabled=false \
--set server.retention=$(getImagesConf 'prometheus' 'time') \
--set server.retention_size=$(getImagesConf 'prometheus' 'size') \
$(getServicePrefix)-$service_name --namespace $(getImagesConf 'k8s' 'namespace') ${yaml_dir} charts/$service_name"

if eval "$helm_cmd $conf_cmd"; then
  sendLog "Do $helm_cmd $service_name successful!" 1 g
else
  sendLog "Do $helm_cmd $service_name  failed!" 3
  exit 1
fi

if [ "${helm_mode}" == "yaml_apply" ]; then
  yamlApply "$service_name"
fi
