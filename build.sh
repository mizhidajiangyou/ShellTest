#!/usr/bin/env bash
# 该脚本用于打包项目
#set -x
#shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

# 将common.sh转换为一个sh脚本
function make_common_file() {
  local file_data
  # shellcheck disable=SC2207
  base_function_name_list=($(grep -v source_all_base_function "${SHELL_HOME}"common/common.sh | grep -v common | awk '/source/{print $2}'))
  for ba in ${base_function_name_list[*]}; do
    file_data=$(grep -v '#!/usr/bin/env bash' "${SHELL_HOME}"common/base/"${ba}")
    echo "$file_data" >>"$common_build_file"
  done
  grep -Ev "source [a-zA-Z0-9]+\.sh" "${SHELL_HOME}common/common.sh" | sed '/^\s*$/d' |grep -v 'common/base' |grep -v 'common/common.sh' >>"$common_build_file"
  sendLog "Make common file successful." 0
}

function main() {
  local file_name=$1
  local build_result_file_name=${2:-build_result.sh}
  if [ ! -f "${file_name}" ]; then
    echo "not find $file_data"
    exit 1
  fi
   common_build_file="$(mktemp)"
  # shellcheck disable=SC2016
  if grep -q 'common/common.sh' "$file_name"; then
    make_common_file
  fi
  {
    echo '#!/bin/bash'
    # shellcheck disable=SC2016
    echo 'SHELL_HOME="$(pwd)/"'
    cat "${common_build_file}"
    # shellcheck disable=SC2016
    grep -v 'common/common.sh' "${file_name}" | grep -v '#!/usr/bin/env bash'
  } >"$build_result_file_name"
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    sendLog "Build_successful! result in $build_result_file_name" 1 g
  else
    sendLog "Build_failed!" 3
  fi
  rm -rf "${common_build_file}"
  chmod +x "${build_result_file_name}"
  if checkCommand shc ;then
    sendLog "do encryption file,it will generate ${build_result_file_name}.x and ${build_result_file_name}.x.c" 1 b
    shc -r -f "${build_result_file_name}"
  fi
}

main "$1" "$2"
