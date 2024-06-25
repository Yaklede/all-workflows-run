#!/bin/bash

JOB_COUNT="${USE_JOB_COUNT:-1}"
WORKFLOW_REGEX="${WORKFLOWS_PATTERN:-default_pattern}"

ACCESS_TOKEN="${ACCESS_TOKEN}"

API_URL="https://api.github.com/repos/owner/repo/actions/workflows"

function getAllWorkflows() {
  curl -s -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL | jq -r '.workflows[] | "\(.name) \(.path)"'
}

function getFilteredWorkflows() {
  local regex=$1
  getAllWorkflows | grep -i "$regex"
}

function runWorkflows() {
  local regex=$1
  local jobCount=$2
  getFilteredWorkflows "$regex" | head -n $jobCount | while read -r name path; do
    echo "Dispatching workflow: $name"
    curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL/$path/dispatches \
         -H "Accept: application/vnd.github.v3+json" \
         -d '{"ref":"main"}' > /dev/null
    echo "Workflow dispatched successfully."
  done
}

# 메인 실행
runWorkflows "$WORKFLOW_REGEX" $JOB_COUNT
