#!/usr/bin/env bash

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh


function do_download() {
  echo "do"
}

function main() {
    sendLog "Do make ${tag} package." 1
    case ${mode} in
    build)
      do_download
      tar_pack
      ;;
    *)
      sendLog "No ${mode} mode ,do noting !"
      ;;
    esac
}

# tag
mode="$1"
tag="$2"

main