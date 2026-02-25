#!/usr/bin/env bash
# Get task details by ID.
# Usage: bash get-task.sh <task_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: get-task.sh <task_id>}"

curl -sf "${MESH_API_URL}/api/v1/tasks/${TASK_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
