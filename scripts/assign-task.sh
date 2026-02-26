#!/usr/bin/env bash
# Assign or unassign a task.
# Usage: bash assign-task.sh <task_id> <agent_id>
#        bash assign-task.sh <task_id> --unassign
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: assign-task.sh <task_id> <agent_id|--unassign>}"
AGENT_OR_FLAG="${2:?Usage: assign-task.sh <task_id> <agent_id|--unassign>}"

if [[ "$AGENT_OR_FLAG" == "--unassign" ]]; then
  BODY='{"assignee_type": "unassigned"}'
else
  BODY=$(jq -n \
    --arg id "$AGENT_OR_FLAG" \
    '{assignee_id: $id, assignee_type: "agent"}')
fi

mesh_curl -X PATCH "${MESH_API_URL}/api/v1/tasks/${TASK_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
