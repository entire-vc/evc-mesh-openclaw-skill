#!/usr/bin/env bash
# Delete a task by ID.
# Usage: bash delete-task.sh <task_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: delete-task.sh <task_id>}"

HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' -X DELETE \
  "${MESH_API_URL}/api/v1/tasks/${TASK_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")

if [[ "$HTTP_CODE" == "204" ]]; then
  echo "Task ${TASK_ID} deleted successfully."
else
  echo "Error: unexpected HTTP status ${HTTP_CODE}" >&2
  exit 1
fi
