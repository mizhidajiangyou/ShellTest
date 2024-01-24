#!/bin/bash
# 用于确认环境基础变量是否存在

now_path="$(pwd)/"
# 配置环境变量的文件
bash_file="${HOME}/.bashrc"
if [ "${SHELL_HOME}" != "${now_path}" ];then
    if [ "${SHELL_HOME}" == "" ];then
       printf "当前环境变量SHELL_HOME为空，将自动添加！%s/\n" "${now_path}"
       echo 'export SHELL_HOME="'"${now_path}"'/"' >> "${bash_file}"
       # shellcheck disable=SC1090
       source "${bash_file}"
       exit 0
    fi
    printf "当前环境变量SHELL_HOME为%s,非当前目录，请手动确认！\n" "${SHELL_HOME}"
fi


