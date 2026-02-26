#!/usr/bin/env bash
# List comments on a task.
# Usage: bash list-comments.sh <task_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: list-comments.sh <task_id>}"

mesh_curl "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/comments" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
