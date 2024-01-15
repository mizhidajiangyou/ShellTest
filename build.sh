#!/usr/bin/env bash
# 该脚本用于打包项目
#set -x

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
  # shellcheck disable=SC1090
  source "$common_build_file"
  print_color "make common file successful" g
}

function main() {
  local file_name=$1
  if [ ! -f "${file_name}" ]; then
    echo "not find $file_data"
    exit 1
  fi
  # shellcheck disable=SC2016
  if grep -q 'source "${SHELL_HOME}"common/common.sh' "$file_name"; then
    common_build_file=".common_$(date '+%N').sh"
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
    print_color "build_successful! result in $build_result_file_name" g
  else
    print_color "build_failed!" r
  fi
  rm -rf "${common_build_file}"
  if checkCommand shc ;then
    print_color "do encryption file,it will generate $1.x and $1.x.c" b
    shc -r -f build_result.sh
  fi
}

build_result_file_name="build_result.sh"
main "$1"
