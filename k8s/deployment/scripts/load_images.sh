#!/bin/bash

# 指定目录
directory="images"

# 遍历目录下的子目录
for dir in "$directory"/*; do
  if [ -d "$dir" ]; then

    pushd "$dir" &> /dev/null || exit 1

    for file in *.tar; do
      if [ -f "$file" ]; then
        docker load -i "$file"
      fi
    done

    popd &> /dev/null || exit 1
  fi
done

echo "Do docker load fi."