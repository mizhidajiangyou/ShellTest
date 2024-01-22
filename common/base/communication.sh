#!/usr/bin/env bash

### 通信模块 ###
## 根据账户密码远程执行命令

function checkExpect() {
  if ! checkCommand "expect"; then
    sendLog "must have command expect! please check" 3 r
    exit 1
  fi
}

function runExpectFile() {
  local exp_file=$1 delete=${2:-true} show=${3:-true} command=${4:-f} result
  sendLog "do run expect file ${exp_file}" 0
  if ! result=$(expect "-${command}" "${exp_file}"); then
    sendLog "run expect file failed!" 3 r
    exit 1
  fi
  if [ "${show}" == "true" ]; then
    echo "${result}"
  fi
  echo "${result}" >>"${EXPECT_RESULT_FILE}"
  if [ "${delete}" == "true" ]; then
    sendLog "do delete expect file ${exp_file}" 0
    rm -rf "${exp_file}"
  fi
  return 0

}

function expectBash() {
  checkExpect
  local user=${1:-root}
  shift
  local ip=$1
  shift
  local passwd=${1:-password}
  shift
  # shellcheck disable=SC2124
  local bash_command="$@"
  if [ -z "${ip}" ]; then
    sendLog "error! plead send ip . usage: expectBash user ip passwd bash_command " 3 r &>/dev/null
  fi
  if ! checkIp "$ip"; then
    return 1
  fi
  # shellcheck disable=SC2155
  local exp_name=".$(date '+%N').exp"
  cat >"${exp_name}" <<EOF
#!/usr/bin/expect

set timeout $EXPECT_TIME_OUT
spawn ssh ${user}@${ip}
expect {
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "password:" {
        send "${passwd}\r"
    }
}
expect "${EXPECT_PROMPT}"
send "${bash_command[*]}\r"
send "exit\r"
expect eof
EOF
  sendLog "expect command: ${bash_command[*]}" 0

  runExpectFile "${exp_name}"

}

function expectScp() {
  checkExpect
  # shellcheck disable=SC2124
  local local_path="$1"
  local end_path="$2"
  local passwd="$3"
  # shellcheck disable=SC2155
  local exp_name=".$(date '+%N').exp"
  cat >"${exp_name}" <<EOF
#!/usr/bin/expect

set timeout $EXPECT_TIME_OUT
spawn scp ${local_path} ${end_path}
expect {
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "password:" {
        send "${passwd}\r"
        expect "${EXPECT_PROMPT}"
    }
}
EOF
  runExpectFile "${exp_name}"


}

function expectIt() {
  checkExpect
  local user=${1:-root}
  shift
  local ip=$1
  shift
  local passwd=${1:-password}
  shift
  if [ -z "${ip}" ]; then
    sendLog "error! plead send ip . usage: expectBash user ip passwd bash_command " 3 r &>/dev/null
  fi
  if ! checkIp "$ip"; then
    return 1
  fi
  # shellcheck disable=SC2155
  local exp_name=".$(date '+%N').exp"
  cat >"${exp_name}" <<EOF
#!/usr/bin/expect

set timeout -1
spawn ssh ${user}@${ip}
expect {
    "yes/no" {
        send "yes\r"
        exp_continue
    }
    "password:" {
        send "${passwd}\r"
    }
}
interact

EOF

  sendLog "used interact mod ! check in 3s"
  countdown 3
  expect  "${exp_name}"

  rm -rf "${exp_name}"
}
