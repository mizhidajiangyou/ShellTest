#!/usr/bin/env bash
# 该脚本用于linux系统间快速免密
#shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function make_sshkey_file() {
  cat >"${temp_key_file_name}.sh" <<EOF
#!/usr/bin/env bash

key_file="$HOME/.ssh/id_rsa"

if [ ! -f "\${key_file}" ]; then
  echo "Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -f "\$key_file" -N ""
  echo "SSH key generated."
else
  echo "SSH key already exists."
fi
if [ ! -f ~/.ssh/authorized_keys ];then
 touch ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys
EOF
  # 生成可执行文件
  # "${SHELL_HOME}"build.sh "$(pwd)/${temp_key_file_name}" "${temp_key_file_name}.sh"
}

function main() {
  if [ -z "${HOSTS_MACHINES}"  ];then
    sendLog "配置文件中的地址数目为0，请检查" 3
    exit 1
  fi
  local i
  make_sshkey_file
  for i in ${HOSTS_MACHINES[*]}; do
    # 先检测地址是否可以连通
    waitIpReady "$i"
    expectScp "${temp_key_file_name}.sh" "${ssh_user}@${i}:~" "${ssh_password}"
    expectBash "${ssh_user}" "${i}" "${ssh_password}" bash "${temp_key_file_name}.sh"
    expectScp "${ssh_user}@${i}:~/.ssh/id_rsa.pub" ".${i}.pub"  "${ssh_password}"
    cat ".${i}.pub" >> "${temp_all_key_file_name}"
  done

  for i in ${HOSTS_MACHINES[*]}; do
    expectScp "${temp_all_key_file_name}" "${ssh_user}@${i}:~" "${ssh_password}"
    expectBash "${ssh_user}" "${i}" "${ssh_password}" "grep -vxFf ~/.ssh/authorized_keys ${temp_all_key_file_name}  >> ~/.ssh/authorized_keys"
  done

  sendLog "do no passwd successful!"
}

temp_key_file_name=".sshkey"
temp_all_key_file_name=".all_sshkey"
ssh_user="root"
ssh_password="password"
echo > "${temp_all_key_file_name}"
# 主函数
main
