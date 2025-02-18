#!/bin/bash

# shellcheck disable=SC1090
source "${SHELL_HOME}"common/common.sh

function hGet() {
  get_url="$1"
  curl -X GET -L -H "PRIVATE-TOKEN: $private_token" "$get_url"
}

function hPut() {
  put_url="$1"
  curl -X PUT -L -H "PRIVATE-TOKEN: $private_token" "$put_url"
}

function hPost() {
  post_url="$1"
  curl -X POST -L -H "PRIVATE-TOKEN: $private_token" "$post_url"
}

function hPutJson() {
  post_url="$1"
  json_data="$2"
  curl -X PUT -L -H "PRIVATE-TOKEN: $private_token" -H "Content-Type: application/json" --data "$json_data" "$post_url"
}

function hDelete() {
  post_url="$1"
  curl -X DELETE -L -H "PRIVATE-TOKEN: $private_token" "$post_url"
}

function createBranch() {
  # 项目id
  br_pr_id="$1"
  # 原分支
  old_branch="$2"
  # 新分支
  new_branch_name="$3"
  hPost "${HTTP_HEADER}"'projects/'"${br_pr_id}"'/repository/branches?branch_name='"${new_branch_name}"'&ref='"${old_branch}"
}

# 务必保证参数的message和tag_name一致，返回message
function tagRequset() {
  pro_id="$1"
  request_tag="$2"
  request_describe="$3"
  # shellcheck disable=SC2154
  curl --location --request POST "${HTTP_HEADER}"projects/"${pro_id}"/repository/tags\?private_token="$private_token" \
    -H 'Content-Type: application/json' \
    -d "{
  	    \"tag_name\": \"${request_tag}\",
  	    \"ref\": \"master\",
  	    \"message\": \"${request_tag}\",
  	    \"release_description\": \"${request_tag} 发布 ${request_describe}\"
  	}" | jq -r '.message'

}
function check_merge_open() {
    hGet "${HTTP_HEADER}merge_requests?state=opened&private_token=${private_token}"
}

function mergeRequset() {
  pro_id="$1"
  pro_source_branch="$2"
  pro_target_branch="$3"
  pro_title="$4"
  curl --location --request POST "${HTTP_HEADER}"projects/"${pro_id}"/merge_requests\?private_token="$private_token" \
    -H 'Content-Type: application/json' \
    -d "{
    	      \"source_branch\": \"${pro_source_branch}\",
    	      \"target_branch\": \"${pro_target_branch}\",
    	      \"title\": \"${pro_title}\",
    	      \"assignee_id\": \"${assignee_id}\"
    	  }" | jq '{mr_id:.id,projects_id:.project_id,web_url:.web_url}' >"${LS_FILE}".request_jq_now
}

function deleteBranch() {
  # 项目id
  br_pr_id="$1"
  # 需要删除的分支
  delete_branch="$2"
  if [ "${delete_branch}" == "master" ] || [ "${delete_branch}" == "test" ]; then
    sendLog "you want to delete master or test! it's don't allowed!" 4
  else
    # 需要删除的分支
    hDelete "${HTTP_HEADER}"'projects/'"${br_pr_id}"'/repository/branches/'"${delete_branch}"
  fi

}

function getProject() {
  #hGet "${HTTP_HEADER}"'projects?statistics\=true\&visibility\=private\&per_page\=100\&page\=2\&sort\=asc' >"$git_project"
  echo "skip"
}

function getMergeRequests() {
  # 仓库id
  mr_projects="$1"
  # 请求id
  mr_id="$2"
  hGet "${HTTP_HEADER}"'projects/'"${mr_projects}"'/merge_requests/'"${mr_id}"
}

function getCompare() {
  # 仓库id
  mr_projects="$1"
  # 合入的分支
  mr_from="$2"
  # 请求的分支
  mr_to="$3"
  hGet "${HTTP_HEADER}"'projects/'"${mr_projects}"'/repository/compare?from='"${mr_from}"'&to='"${mr_to}"
}

function doMerge() {
  # 仓库id
  mr_projects="$1"
  # 请求id
  mr_id="$2"
  hPut "${HTTP_HEADER}"'projects/'"${mr_projects}"'/merge_requests/'"${mr_id}"'/merge'

}

function getAllTag() {
  # 仓库id
  projects_id="$1"
  hGet "${HTTP_HEADER}"'projects/'"${projects_id}"'/repository/tags'
}

function getCICDStatus() {
  # 仓库id
  projects_id="$1"
  hGet "${HTTP_HEADER}"'projects/'"${projects_id}"'/pipelines'
}

function getFiles() {
  # 仓库id
  projects_id="$1"
  # 分支
  file_branch="$2"
  # 路径
  file_path="$3"
  # 转码
  url_file_path="$(echo "${file_path}" | tr -d '\n' | od -An -tx1 | tr ' ' % | tr -d '\n')"
  hGet "${HTTP_HEADER}"'projects/'"${projects_id}"'/repository/files/'"${url_file_path}"'?ref='"${file_branch}"

}

function putFiles() {
  # 仓库id
  projects_id="$1"
  # 分支
  file_branch="$2"
  # 路径
  file_path="$3"
  # 数据
  file_content="$4"
  # 组成的json
  file_json_data="{\"branch\": \"${file_branch}\", \"author_email\": \"${git_author_email}\", \"author_name\": \"${git_author_name}\",\"content\": \"${file_content}\", \"commit_message\": \"update file ${file_path}\"}"
  url_file_path="$(echo "${file_path}" | tr -d '\n' | od -An -tx1 | tr ' ' % | tr -d '\n')"
  # 请求路径
  file_url="${HTTP_HEADER}"'projects/'"${projects_id}"'/repository/files/'"${url_file_path}"
  hPutJson "${file_url}" "${file_json_data}"

}



