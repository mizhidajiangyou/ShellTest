#!/bin/bash


ip_list=$(ip a |grep 'state UP' |grep -v noqueue |awk '{gsub(":", "", $2);print $2}')
# 当前可用的网卡
echo "当前可用的网卡如下："
for i in ${ip_list[*]};do
  ip=$(ifconfig "$i" | grep broadcast | awk 'NR=1{print $2}')
  echo "网卡$i:$ip"
done

