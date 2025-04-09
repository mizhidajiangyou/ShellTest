#!/usr/bin/env bash

source scripts/common.sh

option=$1

case "$option" in
dm)
  run_and_cp_from_docker  "$option" \
  "$(configParser "$option" "image" images.cfg)" \
  "/home/${option}/test.conf" \
  "artifact/${option}/conf/test.conf"
  ;;
*)
  echo "no $option in artifact,please check!"
  ;;
esac


