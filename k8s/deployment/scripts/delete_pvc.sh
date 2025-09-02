#!/usr/bin/env bash

source scripts/common.sh


# 设置kubeconfig
setKubeConfig

namespace="$(getImagesConf 'k8s' 'namespace')"

sendLog "start delete pvc"

pvc_list=$(kubectl get pvc -n "${namespace}")

echo "${pvc_list}"

sendLog "please check !"
countdown 15

sendLog "do delete!"
true_pvc_list=$(echo "${pvc_list}" | awk 'NR>1{print $1}')
echo "${true_pvc_list}"

for p in ${true_pvc_list};do
  sendLog "delete pvc $p"
  kubectl delete pvc "$p" -n "$namespace"
done

