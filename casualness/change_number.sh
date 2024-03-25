#!/usr/bin/env bash
# 用于改变json的值

json_file=${1:-data.json}
change_num=${2:-999}
save_file=${3:-data_change.json}

jq 'walk(if type == "number" or (type == "string" and test("^[0-9]+(\\.[0-9]+)?$")) or (type == "string" and test("^[0-9]+%$")) then '"${change_num}"' else . end)' "$json_file" &> "${save_file}"

