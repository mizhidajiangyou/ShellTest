#!/usr/bin/env bash

source scripts/common.sh

function helm_pull_from_image() {
  local full_image="$1" default_version="${2:-0.1.0}"
  local image_tag="${full_image#*:}"
  local version_regex='^(v?)(([0-9]+)\.([0-9]+)\.([0-9]+))(-.+)?$'
  local helm_version="" base_dir="${CHART_SAVE_DIR}"
  local oci_repo="oci://${full_image%:*}"

  mkdir -p ${base_dir}
  sendLog "待处理镜像地址：${full_image}" 0 &>/dev/null

  if [ "${image_tag}" = "${full_image}" ]; then
    sendLog "镜像地址格式错误！未找到 ':' 分隔符（正确格式：域名/项目/镜像名:标签）" 3 &>/dev/null
    return 1
  fi

  sendLog "提取到镜像标签（tag）：${image_tag}" 0 &>/dev/null

  # 执行正则匹配
  if [[ "${image_tag}" =~ ${version_regex} ]]; then
    helm_version="${BASH_REMATCH[2]}"
    sendLog "标签格式符合要求，提取到 Helm 版本号：${helm_version}" 0 &>/dev/null
  else
    helm_version="${default_version}"
  fi

  sendLog "即将执行 Helm 拉取命令：${helm_pull_cmd}" 0 &>/dev/null
  local helm_pull_cmd="helm pull ${oci_repo} --version ${helm_version} --destination $base_dir"
  # 执行命令并检查结果
  if ${helm_pull_cmd}; then
    sendLog "Helm Chart 拉取完成！版本：${helm_version}，OCI 仓库：${oci_repo}" 1 &>/dev/null
    return 0
  else
    sendLog "Helm Chart 拉取失败！请检查：" &>/dev/null
    sendLog "1. OCI 仓库地址是否正确（${oci_repo}）" 3 &>/dev/null
    sendLog "2. Helm 版本号是否存在（${helm_version}）" 3 &>/dev/null
    return 1
  fi
}

function do_save_install_images_charts() {
  local ser url default_version
  ser=$1
  url="$(configParser "${ser}" "image" "images.cfg")"

  case $ser in
  minio | redis | kingbase | mysql | registry)
    default_version="$(configParser "${ser}" "chart_version" "images.cfg")"
    # 判断变量是否存在
    if [ -z "${default_version}" ]; then
      sendLog "${ser}配置文件中chart_version不存在" 3
      exit 1
    else
      sendLog "${ser}配置文件中chart_version存在：${default_version}" 0
    fi
    ;;
  *)
    default_version="0.1.0"
    ;;
  esac
  sendLog "Try save: $url" 0
  if helm_pull_from_image "${url}" "${default_version}" &>/dev/null; then
    sendLog "pull: $url successful" 0 g
  else
    sendLog "pull $url failed." 3
    exit 1
  fi
}

function do_save_other_images() {
  local images_name images_url images_list
  sendLog "Try save other images" 0
  images_list=$(getConfigSection other_images images.cfg | awk '!/^#/ && $0 != ""')
  for images_name in ${images_list[*]}; do
    images_url="$(configParser "other_images" "$images_name" "images.cfg")"
    sendLog "Try save $images_url" 0
    if docker pull "${images_url}" &>/dev/null; then
      docker save "${images_url}" -o images/other/"${images_name}"-"${version}"-"${framework}".tar
      sendLog "Save: $images_url successful" 0 g
    else
      sendLog "Docker pull $images_url failed." 3
      exit 1
    fi
  done
}

function extract_charts() {
  local source_dir=${CHART_SAVE_DIR}
  local dest_dir=${ARTIFACT_DIR}
  # shellcheck disable=SC2155
  local tgz_files=$(find "$source_dir" -maxdepth 1 -type f -name "*.tgz")
  local tgz_file
  # 遍历并解压每个.tgz文件
  for tgz_file in $tgz_files; do
      sendLog "正在解压: $tgz_file 到 $dest_dir" 0
      if tar -zxf "$tgz_file" -C "$dest_dir"; then
          sendLog "解压 $tgz_file 成功" 0
      else
          sendLog "解压 $tgz_file 失败" 3
          exit 1
      fi
  done
}

function main() {
  local version framework
  CHART_SAVE_DIR="charts"
  ARTIFACT_DIR="artifact"
  version=$(configParser "global" "version" "images.cfg")
  framework=$(configParser "global" "framework" "images.cfg")
  sendLog "Do download images. version is ${version} framework is ${framework} ."
  checkDir "${CHART_SAVE_DIR}" "force"
  checkDir "${ARTIFACT_DIR}" "force"
  for_service_do do_save_install_images_charts
  # do_save_other_images
  # 解压
  sendLog "extract tgz" 0
  extract_charts
  sendLog "rm -rf ${CHART_SAVE_DIR}" 0
  # 删除多余文件
  rm -rf "${CHART_SAVE_DIR}"
  sendLog "Do download fi."
}
main