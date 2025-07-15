#!/usr/bin/env bash


random1=$(( RANDOM % 60 + 1 ))
random2=$(( RANDOM % 200 + 1 ))
sleep $random1

# shellcheck disable=SC2051
# shellcheck disable=SC2034
# shellcheck disable=SC2004
for ((i=0; i<${random2}; i++)); do
  dd if=/dev/zero of=/tmp/1.txt bs=1k count=10000 &> /dev/null &
done

