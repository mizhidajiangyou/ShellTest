#!/bin/bash

if [ -f scripts/common.sh ];then
  # shellcheck disable=SC1091
  source scripts/common.sh
else
   echo "文件存在缺失！请检查安装包内容。"
   exit 1
fi

show_version=$(configParser "global" "version" "images.cfg")
echo ''
print_color "当前版本为:"
convert_text "$show_version"

echo ''
echo '可以参考以下命令去进行部署，或者参考README来修改配置。'
echo '如果您需要更多的帮助，请联系该版本包的负责人。'

