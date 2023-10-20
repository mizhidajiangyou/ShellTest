#!/bin/bash
# 用于删除顽固污渍

# 需要删除的命名空间
ns_list=$(kubectl get ns | awk '/Terminating/{print $1}')

# 开启本地代理
kubectl proxy &

# 执行删除
for i in ${ns_list[*]}; do
  # echo "$i"
  kubectl get ns "$i" -o json &>."$i".json
  # 使用 sed 命令进行替换
  # shellcheck disable=SC2094
  jq .spec={} ."$i".json >.temp && mv .temp ."$i".json
  curl -k -H "Content-Type: application/json" -X PUT --data-binary @."$i".json http://127.0.0.1:8001/api/v1/namespaces/"$i"/finalize
  rm -rf ."$i".json*
done

ps -ef | grep 'kubectl proxy' | grep -v grep | awk '{print $2}' | xargs kill -9
