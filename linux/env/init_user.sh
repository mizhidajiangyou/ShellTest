#!/usr/bin/env bash
# 初始化用户
function init_user() {
  # shellcheck disable=SC2046
  if [ $(grep -c "$INIT_USER_NAME" /etc/passwd) -eq 0 ]; then
    useradd -m -p "${INIT_PASSWORD}" -u "$INIT_USER_ID" -U "$INIT_USER_NAME"
  fi
  echo "是否给sudo权限? [y/n] "
  read -t 10 -r user_is_sudo
  if [ "${user_is_sudo}" == "y" ]; then
    # shellcheck disable=SC2046
    if [ $(grep -c "$INIT_USER_NAME ALL=(ALL) NOPASSWD:ALL" /etc/sudoers) -eq 0 ]; then
      chmod 640 /etc/sudoers
      # shellcheck disable=SC2024
      echo "$INIT_USER_NAME ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers
    fi
  fi
  # shellcheck disable=SC2046
  if [ $(grep -c 65536 /etc/security/limits.conf) -eq 0 ]; then
    # shellcheck disable=SC2024
    echo '*     soft     nofile    65536' >>/etc/security/limits.conf
    # shellcheck disable=SC2024
    echo '*     hard     nofile    65536' >>/etc/security/limits.conf
  fi

}

function main() {
  if [ "$(whoami)" != "root" ]; then
    echo "user root to continue!"
    exit 1
  fi
  init_user
}

# 初始化的用户
INIT_USER_NAME="mz001"
# 用户id
INIT_USER_ID="1001"
# 用户密码
INIT_PASSWORD=$(perl -e 'print crypt("mypassword", "password")')
_main



