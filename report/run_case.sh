#!/usr/bin/env bash

# 执行case目录下case-*.sh
# 根据描述describe和执行结果生成测试报告
# e.g. ./run_case.sh "~/Desktop/ShellTest/http/dj/case" "测试" "测试描述"

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function run_test_case() {
  local test_result function_names result_file a b file now_process max_process temp_file
  local success_message=Success fail_message="Failed"
  local success_num=0 fail_num=0 res total=0
  result_file=${1:-test_result_$(now_time_sim).json}
  max_process=${GLOBAL_PROCESS_NUM:-3}
  echo "${result_file}"
  touch "${result_file}"
  echo >"${result_file}"
  test_result+="{\"taskName\": \"${test_task_name}\", \"description\": \"${test_task_describe}\",\
     \"startTime\": \"$(now_time_normal)\", "
  pushd "$test_case_dir" &>/dev/null || exit 1

  # 检查当前目录是否存在以`case`开头的文件
  if ! ls case* 1>/dev/null 2>&1; then
    sendLog "错误: 当前目录不存在以 'case' 开头的文件" 3
    exit 1
  fi
  sendLog "依次执行case文件。" 0
  # source 测试方法
  for file in case*; do
    if source "$file"; then
      sendLog "source $file 执行成功。" 0

      # shellcheck disable=SC2207
      function_names+=($(grep -v '^[#\/]' "${file}" | grep function | awk '/case/{gsub(/\(\)/,"",$2); print $2}'))
    else
      sendLog "source $file 执行失败。" 3
    fi
  done
  # 校验是否存在函数
  if [ -z "${function_names[*]}" ]; then
    sendLog "没有可执行的函数！" 3
    exit 1
  fi

  sendLog "校验是否存在相同的用例函数"
  checkRepeat "${function_names[*]}"
  sendLog "执行测试用例：${function_names[*]}" 0
  test_result+="\"caseData\": [ "
  for a in ${function_names[*]}; do
    local case_start_time case_end_time t case_result
    t=$(mktemp)
    temp_file+="$t "
    {
      case_start_time=$(now_time_normal)
      sendLog "Do function: ${a}" 0
      if ! ${a} &>"${t}"; then
        sendLog "Run ${a} error" 3
        case_result="${fail_message}"
      else
        sendLog "Run ${a} success" 0
        case_result="${success_message}"
      fi
      case_end_time=$(now_time_normal)
      echo " {\"startTime\": \"$case_start_time\",\"endTime\": \"$case_end_time\",\"run_out\":\"$(cat "$t")\",\"result\":\"${case_result}\"}" >"${t}"
    } &
    ((now_process++))
    if [ "$now_process" -ge "$max_process" ]; then
      wait -n
      ((now_process--))
    fi
  done
  wait
  # 结果写入汇总
  for b in ${temp_file[*]}; do
    ((total++))
    res="$(cat "$b")"
    test_result+="${res}"
    if [ "$b" != "$(echo "$temp_file" | awk '{print $NF}')" ]; then
      test_result+=","
    fi
    # shellcheck disable=SC2046
    if [ $(echo "$res" | jq -r .result) == "${success_message}" ]; then
      ((success_num++))
    else
      ((fail_num++))
    fi
    rm -rf "$b"
  done
  test_result+="],"
  test_result+="\"successNum\": ${success_num},"
  test_result+="\"failNum\": ${fail_num},"
  test_result+="\"total\": ${total},"
  test_result+="\"successRate\": \"$(echo "scale=2; ($success_num / $total) * 100" | bc)%\"",
  test_result+="\"endTime\": \"$(now_time_normal)\"} "
  popd &>/dev/null || exit 1
  echo "$test_result" &>"$result_file"
  sendLog "测试结果: $test_result" 0
  sendLog "测试结束，记录存放于文件：$result_file" 0
}

function main() {
  local now_path
  now_path=$(pwd)
  echo "test case dir: $test_case_dir"
  # run_test_case "test_result_$(now_time_sim).json"
  run_test_case ".test.json"
  cd "${now_path}" || exit 1
}

test_case_dir=$1
test_task_name=${2:-test_task_name}
test_task_describe=${3:-test_task_describe}

main
