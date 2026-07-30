#!/usr/bin/env bash

### 通信模块 ###
## 根据账户密码远程执行命令

# 检查本机是否已安装 expect 命令，未安装时终止当前脚本。
function checkExpect() {
  if ! checkCommand "expect"; then
    sendLog "must have command expect! please check" 3 r
    exit 1
  fi
}

# 创建 expect 临时脚本文件，调用方拿到路径后负责注册退出清理。
function createExpectFile() {
  local exp_name tmp_dir
  tmp_dir=${TMPDIR:-/tmp}
  tmp_dir=${tmp_dir%/}

  if exp_name=$(mktemp "${tmp_dir}/shelltest_expect.XXXXXX" 2>/dev/null); then
    exp_name="${exp_name}.exp"
    : >"${exp_name}" || return 1
  else
    exp_name="${tmp_dir}/shelltest_expect.$$.$(date '+%s').$(date '+%N' 2>/dev/null || echo 0).exp"
    : >"${exp_name}" || return 1
  fi

  chmod 600 "${exp_name}" 2>/dev/null || true
  printf '%s\n' "${exp_name}"
}

# 执行 expect 脚本文件，支持控制是否展示输出、是否删除脚本，并支持透传 expect argv 参数。
function runExpectFile() {
  local exp_file=$1 delete=${2:-true} show=${3:-true} command=${4:-f} result status
  if [ "$#" -gt 4 ]; then
    shift 4
  else
    set --
  fi

  if [ -z "${exp_file}" ] || [ ! -f "${exp_file}" ]; then
    sendLog "run expect file failed: expect file not found ${exp_file}" 3 r
    return 1
  fi

  sendLog "do run expect file ${exp_file}" 0
  result=$(expect "-${command}" "${exp_file}" "$@")
  status=$?

  if [ "${show}" == "true" ] && [ -n "${result}" ]; then
    echo "${result}"
  fi

  if [ -n "${EXPECT_RESULT_FILE}" ]; then
    echo "${result}" >>"${EXPECT_RESULT_FILE}"
  fi

  if [ "${delete}" == "true" ]; then
    sendLog "do delete expect file ${exp_file}" 0
    rm -f "${exp_file}"
  fi

  if [ "${status}" -ne 0 ]; then
    sendLog "run expect file failed: ${exp_file}" 3 r
    return "${status}"
  fi
  return 0
}

# 写入 SSH 远程命令执行 expect 模板，模板参数由 runExpectFile 透传的 argv 提供。
function writeExpectSshBashFile() {
  local exp_name=$1
  cat >"${exp_name}" <<'EOF'
#!/usr/bin/expect

set user [lindex $argv 0]
set ip [lindex $argv 1]
set passwd [lindex $argv 2]
set bash_command [lindex $argv 3]
set timeout_value [lindex $argv 5]

if {$timeout_value eq ""} {
    set timeout_value 30
}
set timeout $timeout_value

set ssh_opts [list \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=$timeout_value \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no]

eval spawn ssh $ssh_opts [list "${user}@${ip}"] [list bash] [list -lc] [list $bash_command]
expect {
    -re "yes/no|continue connecting" {
        send "yes\r"
        exp_continue
    }
    -re "(?i)password:" {
        send "${passwd}\r"
        exp_continue
    }
    -re "Permission denied|Connection refused|No route to host|Operation timed out|Connection timed out|Could not resolve hostname" {
        exit 10
    }
    timeout {
        exit 11
    }
    eof {
        catch wait result
        if {[llength $result] >= 4} {
            exit [lindex $result 3]
        }
        exit 0
    }
}
EOF
}

# 写入 SCP 文件传输 expect 模板，完成后等待 eof 并返回 scp 子进程退出码。
function writeExpectScpFile() {
  local exp_name=$1
  cat >"${exp_name}" <<'EOF'
#!/usr/bin/expect

set local_path [lindex $argv 0]
set end_path [lindex $argv 1]
set passwd [lindex $argv 2]
set timeout_value [lindex $argv 3]

if {$timeout_value eq ""} {
    set timeout_value 30
}
set timeout $timeout_value

set scp_opts [list \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=$timeout_value \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no]

eval spawn scp $scp_opts [list $local_path] [list $end_path]
expect {
    -re "yes/no|continue connecting" {
        send "yes\r"
        exp_continue
    }
    -re "(?i)password:" {
        send "${passwd}\r"
        exp_continue
    }
    -re "Permission denied|Connection refused|No route to host|Operation timed out|Connection timed out|Could not resolve hostname|No such file|not a regular file" {
        exit 10
    }
    timeout {
        exit 11
    }
    eof {
        catch wait result
        if {[llength $result] >= 4} {
            exit [lindex $result 3]
        }
        exit 0
    }
}
EOF
}

# 写入交互式 SSH 登录 expect 模板，登录成功后移交给用户 interact。
function writeExpectInteractFile() {
  local exp_name=$1
  cat >"${exp_name}" <<'EOF'
#!/usr/bin/expect

set user [lindex $argv 0]
set ip [lindex $argv 1]
set passwd [lindex $argv 2]

set timeout -1
set ssh_opts [list \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no]

eval spawn ssh $ssh_opts [list "${user}@${ip}"]
expect {
    -re "yes/no|continue connecting" {
        send "yes\r"
        exp_continue
    }
    -re "(?i)password:" {
        send "${passwd}\r"
    }
    -re "Permission denied|Connection refused|No route to host|Operation timed out|Connection timed out|Could not resolve hostname" {
        exit 10
    }
    eof {
        exit 11
    }
}
interact
EOF
}

# 判断本机是否已安装 sshpass，只返回状态，不终止脚本，便于按环境回退。
function checkSshpass() {
  command -v sshpass &>/dev/null
}

# 使用 sshpass 执行一条需要密码认证的命令；密码为空时直接执行原命令，兼容免密登录。
function runSshpassCommand() {
  local passwd=$1
  shift || true

  if [ "$#" -eq 0 ]; then
    sendLog "error! runSshpassCommand needs command" 3 r
    return 1
  fi

  if [ -z "${passwd}" ]; then
    "$@"
    return $?
  fi

  if ! checkSshpass; then
    sendLog "sshpass command not found" 2 y
    return 127
  fi

  SSHPASS=${passwd} sshpass -e "$@"
}

# 使用 sshpass/ssh 远程执行命令；支持首次连接自动确认 host key，也兼容已有 SSH 免密登录。
function sshpassBash() {
  local user=${1:-root}
  shift || true
  local ip=$1
  shift || true
  local passwd=${1:-}
  shift || true
  local bash_command="$*" timeout_value

  if [ -z "${ip}" ]; then
    sendLog "error! please send ip. usage: sshpassBash user ip passwd bash_command" 3 r
    return 1
  fi
  if [ -z "${bash_command}" ]; then
    sendLog "error! please send bash_command. usage: sshpassBash user ip passwd bash_command" 3 r
    return 1
  fi
  if ! checkIp "${ip}"; then
    sendLog "ip ${ip} is unreachable" 3 r
    return 1
  fi

  timeout_value=${EXPECT_TIME_OUT:-30}
  sendLog "sshpass command: ${bash_command}" 0
  if [ -z "${passwd}" ]; then
    ssh \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="${timeout_value}" \
      -o BatchMode=yes \
      -o PreferredAuthentications=publickey \
      "${user}@${ip}" bash -lc "${bash_command}"
    return $?
  fi

  runSshpassCommand "${passwd}" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout="${timeout_value}" \
    -o PreferredAuthentications=publickey,password,keyboard-interactive \
    "${user}@${ip}" bash -lc "${bash_command}"
}

# 使用 sshpass/scp 传输文件；支持首次连接自动确认 host key，也兼容已有 SSH 免密登录。
function sshpassScp() {
  local local_path=$1
  local end_path=$2
  local passwd=$3
  local timeout_value

  if [ -z "${local_path}" ] || [ -z "${end_path}" ]; then
    sendLog "error! usage: sshpassScp local_path end_path passwd" 3 r
    return 1
  fi

  timeout_value=${EXPECT_TIME_OUT:-30}
  if [ -z "${passwd}" ]; then
    scp \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      -o ConnectTimeout="${timeout_value}" \
      -o BatchMode=yes \
      -o PreferredAuthentications=publickey \
      "${local_path}" "${end_path}"
    return $?
  fi

  runSshpassCommand "${passwd}" scp \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout="${timeout_value}" \
    -o PreferredAuthentications=publickey,password,keyboard-interactive \
    "${local_path}" "${end_path}"
}

# 优先使用 sshpass 执行远程命令；缺少 sshpass 时回退到 expect，保留密码场景兼容性。
function passwordBash() {
  local user=${1:-root}
  local ip=$2
  local passwd=$3
  shift 3 || true

  if [ -z "${passwd}" ] || checkSshpass; then
    sshpassBash "${user}" "${ip}" "${passwd}" "$@"
    return $?
  fi
  expectBash "${user}" "${ip}" "${passwd}" "$@"
}

# 优先使用 sshpass 传输文件；缺少 sshpass 时回退到 expect，保留密码场景兼容性。
function passwordScp() {
  local local_path=$1
  local end_path=$2
  local passwd=$3

  if [ -z "${passwd}" ] || checkSshpass; then
    sshpassScp "${local_path}" "${end_path}" "${passwd}"
    return $?
  fi
  expectScp "${local_path}" "${end_path}" "${passwd}"
}

# 使用账号、IP、密码登录远端主机并执行一条 bash 命令，返回远程命令退出码。
function expectBash() {
  checkExpect
  local user=${1:-root}
  shift || true
  local ip=$1
  shift || true
  local passwd=${1:-password}
  shift || true
  local bash_command="$*"
  local exp_name timeout_value prompt

  if [ -z "${ip}" ]; then
    sendLog "error! please send ip. usage: expectBash user ip passwd bash_command" 3 r
    return 1
  fi
  if [ -z "${bash_command}" ]; then
    sendLog "error! please send bash_command. usage: expectBash user ip passwd bash_command" 3 r
    return 1
  fi
  if ! checkIp "${ip}"; then
    sendLog "ip ${ip} is unreachable" 3 r
    return 1
  fi

  exp_name=$(createExpectFile) || return 1
  if declare -F registerExitCleanFile &>/dev/null; then
    registerExitCleanFile "${exp_name}"
  fi
  writeExpectSshBashFile "${exp_name}"
  sendLog "expect command: ${bash_command}" 0

  timeout_value=${EXPECT_TIME_OUT:-30}
  prompt=${EXPECT_PROMPT:-}
  runExpectFile "${exp_name}" true true f "${user}" "${ip}" "${passwd}" "${bash_command}" "${prompt}" "${timeout_value}"
}

# 使用密码认证执行 scp 文件传输，兼容本地到远端和远端到本地路径。
function expectScp() {
  checkExpect
  local local_path="$1"
  local end_path="$2"
  local passwd="$3"
  local exp_name timeout_value

  if [ -z "${local_path}" ] || [ -z "${end_path}" ]; then
    sendLog "error! usage: expectScp local_path end_path passwd" 3 r
    return 1
  fi

  exp_name=$(createExpectFile) || return 1
  if declare -F registerExitCleanFile &>/dev/null; then
    registerExitCleanFile "${exp_name}"
  fi
  writeExpectScpFile "${exp_name}"

  timeout_value=${EXPECT_TIME_OUT:-30}
  runExpectFile "${exp_name}" true true f "${local_path}" "${end_path}" "${passwd}" "${timeout_value}"
}

# 使用账号、IP、密码进入交互式 SSH 会话。
function expectIt() {
  checkExpect
  local user=${1:-root}
  shift || true
  local ip=$1
  shift || true
  local passwd=${1:-password}
  shift || true
  local exp_name

  if [ -z "${ip}" ]; then
    sendLog "error! please send ip. usage: expectIt user ip passwd" 3 r
    return 1
  fi
  if ! checkIp "${ip}"; then
    sendLog "ip ${ip} is unreachable" 3 r
    return 1
  fi

  exp_name=$(createExpectFile) || return 1
  if declare -F registerExitCleanFile &>/dev/null; then
    registerExitCleanFile "${exp_name}"
  fi
  writeExpectInteractFile "${exp_name}"

  sendLog "used interact mod ! check in 3s" 1
  countdown 3
  runExpectFile "${exp_name}" true true f "${user}" "${ip}" "${passwd}"
}
