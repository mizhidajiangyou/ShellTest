#!/usr/bin/env bash

### 通信模块 ###
## 根据账户密码远程执行命令

function checkExpect() {
  if ! checkCommand "expect"; then
    sendLog "must have command expect! please check" 3 r
    exit 1
  fi
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
    sendLog "error! plead send ip . usage: expectBash user ip passwd bash_command " 3 r
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
expect "#"
send "${bash_command[*]}\r"
send "exit\r"
expect eof
EOF
  sendLog "expect command ${bash_command[*]}" 0

  if expect "${exp_name}" >>"${EXPECT_RESULT_FILE}"; then
    # rm -rf "${exp_name}"
    return 0
  else
    sendLog "run expect file failed!" 3 r
    return 1
  fi

}
