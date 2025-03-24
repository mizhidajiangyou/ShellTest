#!/usr/bin/env bash
# 该脚本用于安装docker

source scripts/common.sh

function start_service() {
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

  config_server "${data_path}"

  systemctl enable docker
  systemctl start docker
}

function install_package() {
  print_color "将要解压的包文件为：${package_name}"
  tar -xvf "${package_name}" -C "${install_path}"
  cd "${install_path}" || exit 1
  ls |grep "${service_name}"
  cd docker || exit 1
  if ! ./docker --version &>/dev/null; then
    print_color "docker 命令执行失败！" r
    exit 1
  else
    cp ./* /usr/bin
  fi
  start_service
}

function config_server() {
  local docker_data_root_path=${1:-/data/docker_data}
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

function get_network_pkg() {
  local new_version used
  local base_url="https://mirrors.aliyun.com/docker-ce/"
  local path_url="/linux/static/stable/"
  local framework_name="x86_64/"
  local url="$base_url$path_url$framework_name"
  new_version=$(curl -s "$url" | grep -Eo 'docker-[0-9]+\.[0-9]+\.[0-9]+\.tgz' | sort -Vur | head -n 1)
  echo "当前可以自动下载的mysql版本为:${new_version}"
  # shellcheck disable=SC2162
  read -p "请输入需要安装的包名: " used
  wget "${url}${used}"
  package_name=${used}
}

function main() {

  service_name="docker"
  # 是否联网安装判断
  # shellcheck disable=SC2155
  local network_enable="$(configParser "global" "network" "images.cfg")"
  # 安装目录设置
  # shellcheck disable=SC2155
  install_path="$(configParser "storage" "install_path" "images.cfg")"
  # 数据目录
  data_path="$(configParser "docker" "data_path" "images.cfg")"
  # 确保目录
  checkDir "${install_path}" force
  checkDir "${data_path}" force
  package_name="$(configParser "$service_name" "image" "images.cfg")"
  if ${network_enable}; then
    get_network_pkg
    install_package "${package_name}"
  else
    package_name="artifact/${service_name}/${package_name}"
    install_package "$package_name"
  fi
}

main
