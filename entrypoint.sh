#!/bin/bash

set -e

JOB_COUNT="${USE_JOB_COUNT:-1}"  # 기본값 1로 설정
WORKFLOW_REGEX="${WORKFLOWS_PATTERN:-.*}"  # 기본값 모든 워크플로우로 설정

ACCESS_TOKEN="${ACCESS_TOKEN}"

OWNER=$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f1)
REPO=$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f2)
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows"

function getAllWorkflows() {
  response=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL)

  # 응답이 올바른지 확인
  echo "API Response: $response"

  echo "$response" | jq -r '.workflows[] | "\(.name) \(.path) \(.id)"'
}

function getFilteredWorkflows() {
  local regex=$1
  getAllWorkflows | grep -i "$regex"
}

function runWorkflows() {
  local regex=$1
  local jobCount=$2
  getFilteredWorkflows "$regex" | head -n $jobCount | while read -r name path id; do
    echo "Dispatching workflow: $name (ID: $id)"
    dispatchResponse=$(curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL/$path/dispatches \
         -H "Accept: application/vnd.github.v3+json" \
         -d '{"ref":"main"}')
    echo "Dispatch response: $dispatchResponse"
    echo "Workflow dispatched successfully."
  done
}

# 메인 실행
runWorkflows "$WORKFLOW_REGEX" $JOB_COUNT
