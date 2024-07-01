#!/usr/bin/env bash
# 该脚本用于安装docker

function get_docker_pkg() {
  local new_docker_version ts used_version

  new_docker_version=$(curl -s "$docker_url" | grep -Eo 'docker-[0-9]+\.[0-9]+\.[0-9]+\.tgz' | sort -Vur | head -n 1)
  print_color "当前可以安装的最新版本docker为:${new_docker_version}" b
  # shellcheck disable=SC2162
  read -p "是否使用最新版本安装？y/n  " ts
  if [ "$ts" == "y" ]; then
    wget "${docker_url}${new_docker_version}"
    docker_package_name=${new_docker_version}
  else
    # shellcheck disable=SC2162
    read -p "请输入需要安装的版本: " used_version
    wget "${docker_url}docker-${used_version}.tgz"
    # check_file_can_download $base_url$path_url
    docker_package_name=docker-${used_version}.tgz
  fi

}

function start_docker_service() {
  if [ -f /lib/systemd/system/docker.service ]; then
    echo '存在文件/lib/systemd/system/docker.service 不进行文件生成。'
  else
    # shellcheck disable=SC2016
    cat >/lib/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF
  fi
  # shellcheck disable=SC2162
  read -p "是否生成docker默认配置项？ y/n " docker_config_enable
  if [ "${docker_config_enable}" == "y" ]; then
    # shellcheck disable=SC2162
    read -p "输入docker存放数据路径，默认为/data ." docker_data_path
    config_docker "${docker_data_path}"
  fi
  systemctl enable docker
  systemctl start docker
}

function install_docker() {
  print_color "将要解压的包文件为：${docker_package_name}"
  tar -zxvf "${docker_package_name}"
  cd docker || exit 1
  if ! ./docker --version &>/dev/null; then
    print_color "docker 命令执行失败！" r
    exit 1
  else
    cp ./* /usr/bin
  fi
  start_docker_service
}

function config_docker() {
  local docker_data_root_path=${1:-/data}
  if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker/
    cat >"/etc/docker/daemon.json" <<EOF
{
  "data-root": "$docker_data_root_path",
  "hosts": ["tcp://0.0.0.0:2375","unix:///var/run/docker.sock"]
}
EOF
  else
    echo "存在配置文件，请手动更改。"
  fi

}

function main() {
  # shellcheck disable=SC1090
  source "${SHELL_HOME}"common/common.sh

  local base_url="https://mirrors.aliyun.com/docker-ce/"
  local path_url="/linux/static/stable/"
  local framework_name="x86_64/"
  local docker_package_name
  if [[ ! $(uname -m) =~ "x86" ]]; then
    framework_name='aarch64/'
  fi
  local docker_url="$base_url$path_url$framework_name"
  # shellcheck disable=SC2162
  read -p "是否使用本地包安装?y/n" user_local_pkg
  if [ "$user_local_pkg" == "y" ]; then
    # shellcheck disable=SC2162
    read -p "请把包放在当前目录下，并输入docker包名称。" docker_package_name
    if [ ! -f "$docker_package_name" ]; then
      print_color "未找到输入的包名称！" r
      exit 1
    fi
    install_docker
  else
    get_docker_pkg
    install_docker
  fi

}

main
