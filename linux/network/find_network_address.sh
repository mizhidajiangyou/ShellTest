#!/bin/bash

for i in {50..200}
do
    ping -c 1 -W 1 192.168.1."$i" > /dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        echo "192.168.1.$i is available."
        exit 0
    fi
done

echo "No available IP found."
exit 1