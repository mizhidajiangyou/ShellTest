#!/usr/bin/env bash

source scripts/common.sh


function do_concise_cfg() {
  # shellcheck disable=SC2046
  filter_config_sections images.cfg \
    $(configParser "global" "package_save" images.cfg) \
    $(configParser "install" "service" images.cfg) &>images.cfg-new

  mv images.cfg-new images.cfg
}

function do_clean_file() {
  local ser
  ser=$(configParser "install" "service" images.cfg)
  clean_install_dir install "${ser}"

}

function _main() {
  if [[ "${CICD_PACKAGE_SAVED_TYPE}" == "CONCISE" ]]; then
    do_concise_cfg
    do_clean_file
  else
    sendLog "skip concise_file. "
  fi
}

_main
