#!/usr/bin/env bash
# Move task to a different status.
# Usage: bash move-task.sh <task_id> <status_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: move-task.sh <task_id> <status_id>}"
STATUS_ID="${2:?Usage: move-task.sh <task_id> <status_id>}"

BODY=$(jq -n --arg status_id "$STATUS_ID" '{status_id: $status_id}')

mesh_curl -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/move" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
