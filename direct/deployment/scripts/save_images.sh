#!/usr/bin/env bash

source scripts/common.sh

function do_save_install_images() {
  local ser url
  ser=$1
  url="$(configParser "${ser}" "url" "images.cfg")/$(configParser "${ser}" "image" "images.cfg")"
  sendLog "Try save: $url" 0
  if curl -s "$url" -o images/install/"${ser}"-"${version}"-"${framework}".tar &>/dev/null; then
    sendLog "Save: $url successful" 0 g
  else
    sendLog "save  $url failed." 3
    exit 1
  fi
}

function do_save_other_images() {
  local images_name images_url images_list
  images_list=$(getConfigSection other_images images.cfg)
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

function main() {
  local version framework
  version=$(configParser "global" "version" "images.cfg")
  framework=$(configParser "global" "framework" "images.cfg")
  sendLog "Do download images. version is ${version} framework is ${framework} ."
  checkDir "images" "force"
  checkDir "images/install" "force"
  checkDir "images/other" "force"

  for_service_do do_save_install_images
  do_save_other_images

  sendLog "Do download fi."
}

main
