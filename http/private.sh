#!/bin/bash

# 载入配置
readConfig "${SHELL_HOME}http/http.cfg"
# 部分国产系统export无法生效，采用直接导入的方式
# CURL_OPTS="-s  -w '{\"time_total\": \"%{time_total}\", \"result\": \"%{http_code}\" }' --max-time ${HTTP_MAX_TIME} --retry-delay ${HTTP_RETRY_DELAY} --retry ${HTTP_RETRY} --retry-max-time ${HTTP_RETRY_MAX_TIME}"

# 类似curl用法
function doHttpRequest {
  local options=("$@")
  local url method body headers action file response cul_option curl_command error
  # 初始化错误文件
  error=$(mktemp)

  if [ "${#options[@]}" -eq 0 ]; then
    sendLog "Missing options" 3 &>/dev/null
    return 1
  fi
  if [[ "${options[0]}" != *"="* ]]; then
    for ((i = 0; i < ${#options[@]}; i++)); do
      case "${options[i]}" in
      -u | --url)
        ((i++))
        url="${options[i]}"
        ;;
      -m | --method)
        ((i++))
        method="${options[i]}"
        ;;
      -b | --body | --data | -d)
        ((i++))
        body="${options[i]}"
        ;;
      -H | --headers)
        ((i++))
        headers+=("${options[i]}")
        ;;
      -a | --action)
        ((i++))
        action="${options[i]}"
        ;;
      -f | --file)
        ((i++))
        file="${options[i]}"
        ;;
      *)
        # ignore unknown options
        ;;
      esac
    done
  else
    for option in "${options[@]}"; do
      case "$option" in
      -u=* | --url=*)
        url="${option#*=}"
        ;;
      -m=* | --method=*)
        method="${option#*=}"
        ;;
      -b=* | --body=* | --data=* | -d=*)
        body="${option#*=}"
        ;;
      -H=* | --headers=*)
        headers+=("${option#*=}")
        ;;
      -a=* | --action=*)
        action="${option#*=}"
        ;;
      -f=* | --file=*)
        file="${option#*=}"
        ;;
      *)
        # ignore unknown options
        ;;
      esac
    done
  fi

  # check required options
  if [[ -z "$url" ]]; then
    echo "Missing URL" 3
    return 1
  fi
  if [[ -z "$method" ]]; then
    method="GET"
  fi

  # set request body
  if [[ "$method" =~ ^(POST|PUT|PATCH)$ ]]; then
    cul_option+=("-d" "$body")
    cul_option+=("-X" "$method")
  fi

  # set request headers
  if [[ ${#headers[@]} -ne 0 ]]; then
    for header in "${headers[@]}"; do
      cul_option+=("-H" "${header}")
      # echo "$header"
    done
  fi

  # set download or upload options
  if [[ "$action" == "download" ]]; then
    cul_option+=("-o" "$file")
  elif [[ "$action" == "upload" ]]; then
    cul_option+=("--data-binary" "@$file")
  fi

  curl_command="curl \"${cul_option[*]}\" -s --max-time ${HTTP_MAX_TIME} --retry-delay ${HTTP_RETRY_DELAY} --retry ${HTTP_RETRY}  $url"
  sendLog "now do : $curl_command" 0 &>/dev/null

  # send HTTP request
  response=$(curl "${cul_option[@]}" -s --max-time "${HTTP_MAX_TIME}" --retry-delay "${HTTP_RETRY_DELAY}" --retry "${HTTP_RETRY}" "$url" 2>"$error")
  # 下面这种方式不行，待优化
  # response=$("$curl_command" 2>"$error")

  # log request and response
  # sendLog "http_request" "url=$url method=$method body=$body headers=$headers action=$action file=$file  error=$error" 0

  # check curl command exit code
  if [[ -n $(<"$error") ]]; then
    sendLog "curl command failed! back: $(<"$error")" 3 &>/dev/null
    rm -rf "$error"
    return 1
  else
    sendLog "curl back: ${response}" 0 &>/dev/null
    rm -rf "$error"
    echo "$response"
    return 0
  fi

}

#e.g.
#  local url=$1 token=$2 data=$3
#  doHttpRequest -u "$url"  -m "POST" -d "$data"\
#    -H 'Accept: application/json; charset=utf-8' \
#    -H 'Accept-Language: zh-CN,zh;q=0.9' \
#    -H 'Cache-Control: no-cache' \
#    -H 'Content-Type: text/plain;charset=UTF-8' \
#    -H 'Pragma: no-cache' \
#    -H 'Proxy-Connection: keep-alive' \
#    -H 'token: '"${token}"'' --insecure
