#!/usr/bin/env bash

source scripts/common.sh

# 预读配置忽略报错
readConfig images.cfg &>/dev/null
# shellcheck disable=SC2207
SYSTEM_MACHINE=($(normalize_args "${DOCKER_MACHINES[*]}"))
OTHER_IMAGES_SSH_IMAGE="$(configParser "other_images" "ssh_image" images.cfg)"
OTHER_IMAGES_SSH_IMAGE=${OTHER_IMAGES_SSH_IMAGE:-harbor.hyperchain.cn/wzgroup/build:hosts-tools}
# 通用验证
SSH_KEY_SHECK="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null   "
# sshpass -p '密码' ssh -p 端口号 用户名@IP地址 "命令"
SSHPASS_BASE_COMMAND_SSH="sshpass -p ${SYSTEM_PASSWD} ssh ${SSH_KEY_SHECK}  -p ${SYSTEM_SSH_PORT} ${SYSTEM_USER}@"
# sshpass -p '密码' scp -P 端口号 本地文件路径 用户名@IP地址:远程路径
SSHPASS_BASE_COMMAND_SCP="sshpass -p ${SYSTEM_PASSWD} scp -P ${SYSTEM_SSH_PORT} ${SSH_KEY_SHECK} "

function check_ha_config() {
  local docker_mode install_services service cluster_nodes node_index host_index host_ip deploy_services
  docker_mode="$(configParser "docker" "mode" images.cfg)"
  sendLog "Docker 部署模式：${docker_mode}"
  if [ "${docker_mode}" != "ha" ]; then
    sendLog "当前不是 Docker HA 模式，跳过高可用部署配置检查。"
    exit 1
  fi

  install_services="$(configParser "install" "service" images.cfg)"
  sendLog "Docker HA 模式部署配置："
  for ((node_index = 0; node_index < ${#SYSTEM_MACHINE[@]}; node_index++)); do
    host_index=$((node_index + 1))
    host_ip="${SYSTEM_MACHINE[$node_index]}"
    deploy_services=""
    for service in ${install_services}; do
      cluster_nodes="$(normalize_args "$(configParser "${service}" "cluster_node_chose" images.cfg)")"
      if printf '%s\n' ${cluster_nodes} | grep -Fxq "${host_index}"; then
        deploy_services="${deploy_services} ${service}"
      fi
    done
    deploy_services="${deploy_services# }"
    deploy_services="${deploy_services:-无}"
    sendLog "第${host_index}台主机是 ${host_ip}，将要部署 ${deploy_services} 组件。"
  done
  sendLog "你有10s的时间确认。"
  countdown 10
}

function make_cluster_package() {
  if [ -d .tmp ]; then
    sendLog ".tmp 已存在，跳过集群安装包生成。"
    checkFile ".tmp/cluster_package.tar.gz"
    return
  fi

  # 创建.tmp目录
  mkdir -p .tmp
  # 压缩
  sendLog "make cluster_package.tar.gz "
  tar -zcvf cluster_package.tar.gz . >> "${LOG_FILE}"
  mv cluster_package.tar.gz .tmp
  cp images.cfg .tmp
  checkFile ".tmp/cluster_package.tar.gz"

}

function run_sshpass_in_docker() {
  local docker_name=$1
  shift
  local ip=$1
  shift
  local args=("$@")
  execDockerBash "${docker_name}" "${ip} ${args[*]}"
}

function start_tool() {
  local local_docker_name=$1
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${local_docker_name}"; then
    sendLog "容器 ${local_docker_name} 已存在，请检查。"
    sendLog "如需停用并删除，请执行：docker stop ${local_docker_name}"
    exit 1
  fi
  runDocker "${local_docker_name}" "${OTHER_IMAGES_SSH_IMAGE}" "tmp"
}

function stop_tool() {
  local local_docker_name=$1
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${local_docker_name}"; then
    sendLog "停用临时容器：${local_docker_name}"
    stopDocker "${local_docker_name}"
  fi
}

function do_cluster_install_node() {
  local i=$1
  local local_docker_name local_command remote_file remote_ip command_prefix node_log_file old_log_file
  local_docker_name="${GLOBAL_PREFIX}-host-tool-${i}"
  remote_ip="${SYSTEM_MACHINE[$i]}"
  node_log_file=".tmp/cluster_install_node_${i}.log"
  old_log_file="${LOG_FILE}"
  LOG_FILE="${node_log_file}"
  sendLog "开始部署第$((i + 1))台主机：${remote_ip}"
  # 远端目录
  remote_file="${STORAGE_INSTALL_PATH}node_${i}"
  # 创建对应的容器
  start_tool "${local_docker_name}"
  command_prefix="${SSHPASS_BASE_COMMAND_SSH}${remote_ip}"
  # 传输
  local_command=" mkdir -p ${remote_file}"
  run_sshpass_in_docker "${local_docker_name}" "${command_prefix}" "${local_command}"
  local_command="/tmp/cluster_package.tar.gz ${SYSTEM_MACHINE[$i]}:${remote_file}"
  execDockerBash "${local_docker_name}" "${SSHPASS_BASE_COMMAND_SCP} ${local_command}"
  # 解压
  local_command="tar -zxvf ${remote_file}/cluster_package.tar.gz -C  ${remote_file}"
  run_sshpass_in_docker "${local_docker_name}" "${command_prefix}" "${local_command}"
  # 配置文件同步
  cp .tmp/images.cfg ".tmp/images.cfg.${i}"
  configParser "docker" "node_id" ".tmp/images.cfg.${i}" "${i}"
  local_command="/tmp/images.cfg.${i} ${SYSTEM_MACHINE[$i]}:${remote_file}"
  execDockerBash "${local_docker_name}" "${SSHPASS_BASE_COMMAND_SCP} ${local_command}"
  # 安装
  local_command="\"cd ${remote_file} && make install\""
  run_sshpass_in_docker "${local_docker_name}" "${command_prefix}" "${local_command}"
  sendLog "第$((i + 1))台主机部署完成：${remote_ip}"
  stop_tool "${local_docker_name}"
  LOG_FILE="${old_log_file}"
}

function is_pid_running() {
  local target_pid=$1 running_pid
  for running_pid in $(jobs -pr); do
    if [ "${running_pid}" = "${target_pid}" ]; then
      return 0
    fi
  done
  return 1
}

function print_tool_logs() {
  local node_index=$1
  local local_docker_name="${GLOBAL_PREFIX}-host-tool-${node_index}"
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${local_docker_name}"; then
    sendLog "输出第$((node_index + 1))台主机临时容器最近日志：${local_docker_name}"
    docker logs --tail 20 "${local_docker_name}"
  fi
}

function do_cluster_install() {
  local i pid failed=0 finished=0 timeout start_time now elapsed
  local pids=()
  local finished_nodes=()
  local failed_nodes=()
  timeout="${GLOBAL_ALL_TIMEOUT:-600}"
  start_time=$(date +%s)

  for ((i = 0; i < ${#SYSTEM_MACHINE[@]}; i++)); do
    do_cluster_install_node "${i}" &
    pids+=("$!")
    finished_nodes+=("0")
    sendLog "第$((i + 1))台主机部署任务已启动，日志：docker logs -f ${GLOBAL_PREFIX}-host-tool-${i}"
  done

  while [ "${finished}" -lt "${#pids[@]}" ]; do
    now=$(date +%s)
    elapsed=$((now - start_time))
    if [ "${elapsed}" -ge "${timeout}" ]; then
      failed=1
      sendLog "等待部署超时，超时时间：${timeout}s" 3
      for ((i = 0; i < ${#pids[@]}; i++)); do
        if [ "${finished_nodes[$i]}" = "0" ]; then
          failed_nodes+=("${i}")
          kill "${pids[$i]}" 2>/dev/null || true
          stop_tool "${GLOBAL_PREFIX}-host-tool-${i}"
        fi
      done
      break
    fi

    for ((i = 0; i < ${#pids[@]}; i++)); do
      if [ "${finished_nodes[$i]}" = "1" ]; then
        continue
      fi

      pid="${pids[$i]}"
      if is_pid_running "${pid}"; then
        print_tool_logs "${i}"
        sleep 10
      else
        finished_nodes[$i]="1"
        finished=$((finished + 1))
        if ! wait "${pid}"; then
          failed=1
          failed_nodes+=("${i}")
        fi
      fi
    done
  done

  if [ "${failed}" -ne 0 ]; then
    sendLog "存在主机部署失败，失败节点最后20条 ERROR 日志如下：" 3
    for i in "${failed_nodes[@]}"; do
      sendLog "第$((i + 1))台主机 ERROR 日志:" 3
      grep "ERROR" ".tmp/cluster_install_node_${i}.log" | tail -n 20
      sendLog "更详细日志请查看：.tmp/cluster_install_node_${i}.log；log看不出来的情况下看 docker logs -f ${GLOBAL_PREFIX}-host-tool-${i}" 3
    done
    exit 1
  fi
  sendLog "所有主机部署完成。"
}

function main() {
  check_ha_config
  make_cluster_package
  do_cluster_install
}

main
