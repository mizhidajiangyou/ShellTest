#!/bin/bash

# set -x
# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh
# 载入配置
readConfig "${SHELL_HOME}http/http.cfg"
export CURL_OPTS="-s -w  --max-time ${HTTP_MAX_TIME} --retry-delay ${HTTP_RETRY_DELAY} --retry ${HTTP_RETRY} ----retry-max-time ${HTTP_RETRY_MAX_TIME}"

function doHttpRequest {
  local options=("$@")
  local url method body headers action file response cul_option

  for option in "${options[@]}"; do
    case "$option" in
    -u=* | --url=*)
      url="${option#*=}"
      ;;
    -m=* | --method=*)
      method="${option#*=}"
      ;;
    -b=* | --body=*)
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
  fi

  # set request headers
  if [[ -n "$headers" ]]; then
    for header in "${headers[@]}"; do
        cul_option+=("-H" "${header}")
        echo "$header"
    done
  fi

  # set download or upload options
  if [[ "$action" == "download" ]]; then
    cul_option+=("-o" "$file")
  elif [[ "$action" == "upload" ]]; then
    cul_option+=("--data-binary" "@$file")
  fi

  # send HTTP request
  response=$(curl "${cul_option[@]}" "$url" 2>/dev/null)

  # log request and response
  # sendLog "http_request" "url=$url method=$method body=$body headers=$headers action=$action file=$file  error=$error" 0

  # check curl command exit code
  # shellcheck disable=SC2181
  if [[ $? -ne 0 ]]; then
    echo "curl command failed"
    return 1
  else
    echo "$response"
    return 0
  fi
}

