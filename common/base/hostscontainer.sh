#!/usr/bin/env bash

### 主机操作容器模块 ###

# 获取主机操作容器使用的基础镜像，优先读取 HOSTS_BASE_IMAGE。
function hostsContainerImage() {
  local image=${1:-${HOSTS_BASE_IMAGE:-}}
  if [ -z "${image}" ]; then
    sendLog "HOSTS_BASE_IMAGE is empty, please set [hosts] base_image in global.cfg" 3 r
    return 1
  fi
  printf '%s\n' "${image}"
}

# 检查 docker 命令是否可用。
function checkDocker() {
  if ! command -v docker &>/dev/null; then
    sendLog "must have command docker! please check" 3 r
    return 1
  fi
}

# 判断主机操作容器是否已存在。
function hostsContainerExists() {
  local container_name=${1:-hosts-tools}
  docker container inspect "${container_name}" &>/dev/null
}

# 判断主机操作容器是否正在运行。
function hostsContainerRunning() {
  local container_name=${1:-hosts-tools}
  [ "$(docker inspect -f '{{.State.Running}}' "${container_name}" 2>/dev/null)" = "true" ]
}

# 启动主机操作容器；如果容器已存在但未运行则直接 start。
function hostsContainerStart() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools} image
  image=$(hostsContainerImage "${2:-}") || return 1

  if hostsContainerRunning "${container_name}"; then
    sendLog "hosts container ${container_name} is already running" 0
    return 0
  fi

  if hostsContainerExists "${container_name}"; then
    sendLog "start hosts container ${container_name}" 0
    docker start "${container_name}" >/dev/null
    return $?
  fi

  sendLog "create hosts container ${container_name} from ${image}" 0
  mkdir -p "${SHELL_HOME:-$(pwd)}/res/log"
  docker run -d \
    --name "${container_name}" \
    --workdir /work \
    -v "${SHELL_HOME:-$(pwd)}/linux:/scripts:ro" \
    -v "${SHELL_HOME:-$(pwd)}/res/log:/logs" \
    "${image}" >/dev/null
}

# 构建主机操作基础镜像，默认使用 HOSTS_BASE_IMAGE 作为镜像标签。
function hostsContainerBuildImage() {
  checkDocker || return 1
  local dockerfile_dir=${1:-${SHELL_HOME:-$(pwd)}/docker/build/docker/hosts-tools} image
  image=$(hostsContainerImage "${2:-}") || return 1

  sendLog "build hosts image ${image} from ${dockerfile_dir}" 0
  docker build -t "${image}" "${dockerfile_dir}"
}

# 停止主机操作容器。
function hostsContainerStop() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools}
  if hostsContainerRunning "${container_name}"; then
    sendLog "stop hosts container ${container_name}" 0
    docker stop "${container_name}" >/dev/null
  fi
}

# 删除主机操作容器。
function hostsContainerRemove() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools}
  if hostsContainerExists "${container_name}"; then
    sendLog "remove hosts container ${container_name}" 0
    docker rm -f "${container_name}" >/dev/null
  fi
}

# 重建主机操作容器。
function hostsContainerRestart() {
  local container_name=${1:-hosts-tools} image=${2:-}
  hostsContainerRemove "${container_name}" || return 1
  hostsContainerStart "${container_name}" "${image}"
}

# 拷贝宿主机文件到主机操作容器。
function hostsContainerCopyTo() {
  checkDocker || return 1
  local src=$1 dst=$2 container_name=${3:-hosts-tools}
  if [ -z "${src}" ] || [ -z "${dst}" ]; then
    sendLog "error! usage: hostsContainerCopyTo src dst [container_name]" 3 r
    return 1
  fi
  docker cp "${src}" "${container_name}:${dst}"
}

# 从主机操作容器拷贝文件到宿主机。
function hostsContainerCopyFrom() {
  checkDocker || return 1
  local src=$1 dst=$2 container_name=${3:-hosts-tools}
  if [ -z "${src}" ] || [ -z "${dst}" ]; then
    sendLog "error! usage: hostsContainerCopyFrom src dst [container_name]" 3 r
    return 1
  fi
  docker cp "${container_name}:${src}" "${dst}"
}

# 在主机操作容器内执行命令，输出同时写入容器内日志文件。
function hostsContainerExec() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools} log_file=${2:-/logs/hosts-container.log}
  if [ "$#" -gt 1 ]; then
    shift 2
  else
    set --
  fi

  if [ "$#" -eq 0 ]; then
    sendLog "error! usage: hostsContainerExec container_name log_file command..." 3 r
    return 1
  fi

  if ! hostsContainerRunning "${container_name}"; then
    sendLog "hosts container ${container_name} is not running" 3 r
    return 1
  fi

  docker exec "${container_name}" bash -lc "mkdir -p \"\$(dirname '${log_file}')\" && \"\$@\" 2>&1 | tee -a '${log_file}'" -- "$@"
}

# 在主机操作容器内执行脚本。
function hostsContainerRunScript() {
  local script_path=$1 container_name=${2:-hosts-tools} log_file=${3:-/logs/hosts-container.log}
  if [ "$#" -gt 2 ]; then
    shift 3
  else
    set --
  fi

  if [ -z "${script_path}" ]; then
    sendLog "error! usage: hostsContainerRunScript script_path [container_name] [log_file] [args...]" 3 r
    return 1
  fi

  hostsContainerExec "${container_name}" "${log_file}" bash "${script_path}" "$@"
}

# 在主机操作容器内执行服务器免密脚本。
function hostsContainerRunNoPasswd() {
  local user=$1 passwd=$2 hosts=$3 container_name=${4:-hosts-tools}
  if [ -z "${user}" ] || [ -z "${passwd}" ] || [ -z "${hosts}" ]; then
    sendLog "error! usage: hostsContainerRunNoPasswd user passwd hosts_json [container_name]" 3 r
    return 1
  fi
  hostsContainerRunScript "/scripts/no_passwd_sshpass.sh" "${container_name}" "/logs/no_passwd_sshpass.log" "${user}" "${passwd}" "${hosts}"
}

# 查看主机操作容器内脚本日志。
function hostsContainerShowLog() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools} log_file=${2:-/logs/hosts-container.log}
  docker exec "${container_name}" sh -c "test -f '${log_file}' && cat '${log_file}' || true"
}

# 查看主机操作容器 stdout/stderr 主日志。
function hostsContainerLogs() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools}
  docker logs "${container_name}"
}

# 清理主机操作容器内脚本日志。
function hostsContainerClearLog() {
  checkDocker || return 1
  local container_name=${1:-hosts-tools} log_file=${2:-/logs/hosts-container.log}
  docker exec "${container_name}" sh -c ": >'${log_file}'"
}
