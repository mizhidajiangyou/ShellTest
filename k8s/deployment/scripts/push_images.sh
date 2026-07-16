#!/usr/bin/env bash

source scripts/common.sh

function do_init_reg() {
  local service_name=$1 new_registry="${NEW_REGISTRY}" new_tag="${NEW_TAG}" \
    image_name new_image images_list ima original_image

  if [ "${service_name}" == "other_images" ]; then
    images_list=$(getConfigSection other_images images.cfg | awk '!/^#/ && $0 != ""')
    for ima in ${images_list[*]}; do
      original_image=$(configParser "other_images" "$ima" "images.cfg")
      image_name="$(configParser "other_images" "$ima" "images.cfg" | awk -F'[/:]' '{print $(NF-1)}')"
      new_image="${new_registry}/${image_name}:${new_tag}"
      configParser "other_images" "$ima" "images.cfg" "$new_image"
      do_push_image "$original_image" "$new_image"
      sendLog "push $new_image successful!"
    done
  else
    original_image=$(configParser "$service_name" "image" "images.cfg")
    image_name=$(getImagesConf "$service_name" 'image' | awk -F'[/:]' '{print $(NF-1)}')
    new_image="${new_registry}/${image_name}:${new_tag}"
    configParser "$service_name" "image" "images.cfg" "$new_image"
    do_push_image "$original_image" "$new_image"
    sendLog "push $new_image successful!"
  fi

}

function do_push_image() {
  local original_image=$1 new_image=$2
  sendLog "do tag ${original_image} to ${new_image}" 0
  docker tag "${original_image}" "${new_image}"
  sendLog "do push ${new_image}" 0
  if ! docker push "${new_image}" &>/dev/null; then
    sendLog "do push ${new_image} error!" 3
    exit 1
  fi
}

function main() {
  REGISTRY_ENABLE="$(getImagesConf "k8s" 'ind_reg')"
  if [ "${REGISTRY_ENABLE}" == "true" ]; then
    NEW_REGISTRY="$(getImagesConf "storage" 'registry')/$(getImagesConf "k8s" 'prefix')"
    NEW_TAG="$(getImagesConf "global" 'version')"
    # 备份一下images.cfg
    cp images.cfg images.cfg-bakend
    for_service_do do_init_reg
    do_init_reg "other_images"
  fi
}

main
