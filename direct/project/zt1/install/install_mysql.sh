#!/usr/bin/env bash
# 该脚本用于安装mysql

source scripts/common.sh

function get_network_pkg() {
  local new_version used
  local base_url="https://cdn.mysql.com//Downloads/"
  local path_url="MySQL-8.0/"
  # local framework_name="x86_64/"
  local url="$base_url$path_url"
  new_version=$(curl -s 'https://dev.mysql.com/downloads/mysql/?tpl=platform&os=2&version=8.0&osva=' | grep -E 'mysql-8.0.[0-9]+*' | grep -v td | awk -F= '{print substr($4, 1, length($4)-2)}')
  echo "当前可以自动下载的mysql版本为:${new_version}"
  # shellcheck disable=SC2162
  read -p "请输入需要安装的包名: " used
  wget "${url}${used}"
  package_name=${used}
}

function start_service() {
  if [ -f /lib/systemd/system/docker.service ]; then
    echo '存在文件/lib/systemd/system/docker.service 不进行文件生成。'
  else
    # shellcheck disable=SC2016
    cat >/lib/systemd/system/docker.service <<EOF
[Unit]
Description=MySQL Database Server
After=network.target

[Service]
Type=forking
User=mysql
Group=mysql
ExecStart=/usr/local/mysql-mz/bin/mysqld --basedir=/usr/local/mysql-mz --datadir=/usr/local/mysql-mz/data --defaults-file=/usr/local/mysql-mz/my.cnf
ExecStop=/usr/local/mysql-mz/bin/mysqladmin shutdown
Restart=always
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
  fi
  # shellcheck disable=SC2162
  read -p "是否生成docker默认配置项？ y/n " config_enable
  if [ "${config_enable}" == "y" ]; then
    # shellcheck disable=SC2162
    read -p "输入docker存放数据路径，默认为/data ." data_path
    config_docker "${data_path}"
  fi
  systemctl enable docker
  systemctl start docker
}

function install_package() {
  local package_name=$1
  sendLog "将要解压的包文件为：${package_name}"
  tar -xvf "${package_name}" -C "${install_path}"
  cd "${install_path}" || exit 1
  ls |grep "${service_name}"
  if ! ./docker --version &>/dev/null; then
    print_color "docker 命令执行失败！" r
    exit 1
  else
    #    cp ./* /usr/bin
    sudo bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql-mz --datadir=/usr/local/mysql-mz/data --defaults-file=/usr/local/mysql-mz/my.cnf
    # 后端启动
    sudo bin/mysqld_safe --user=mysql --datadir=/root/services/mysql &
  fi
  start_service
}

function make_config() {
  local data_root_path=${1:-/data}
  if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker/
    cat >"/etc/docker/daemon.json" <<EOF
{
  "data-root": "$data_root_path",
  "hosts": ["tcp://0.0.0.0:2375","unix:///var/run/docker.sock"]
}
EOF
  else
    echo "存在配置文件，请手动更改。"
  fi

}


function main() {
  service_name="mysql"
  # 是否联网安装判断
  # shellcheck disable=SC2155
  local network_enable="$(configParser "global" "network" "images.cfg")"
  # 安装目录设置
  # shellcheck disable=SC2155
  install_path="$(configParser "storage" "install_path" "images.cfg")"
  # 确保目录
  checkDir "${install_path}" force
  package_name
  if ${network_enable}; then
    get_network_pkg
    install_package "${package_name}"
  else
    package_name="artifact/${service_name}/$(configParser "global" "network" "images.cfg")"
    install_package "$package_name"
  fi

}

main
