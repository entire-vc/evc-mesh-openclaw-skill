#!/usr/bin/env bash
# List artifacts attached to a task.
# Usage: bash list-artifacts.sh <task_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: list-artifacts.sh <task_id>}"

curl -sf "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/artifacts" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
