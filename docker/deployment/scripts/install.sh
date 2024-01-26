#!/usr/bin/env bash

source scripts/common.sh

#set -ex

function main() {
    local service_list ser
    service_list=$(configParser install service images.cfg)
    for ser in ${service_list[*]};do

      ./install/install_"${ser}".sh
      pushd docker/"${ser}" &> /dev/null || exit 1
      sendLog "start ${ser} ..."
      if ! ./start.sh ;then
        sendLog "start ${ser} failed! " 3
        exit 1
      fi
      popd &> /dev/null || exit 1
    done

}

main