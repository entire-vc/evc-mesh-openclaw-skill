#!/usr/bin/env bash
# Create a subtask under a parent task.
# Usage: bash create-subtask.sh <parent_task_id> <title> [--priority <p>]
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PARENT_ID="${1:?Usage: create-subtask.sh <parent_task_id> <title>}"
TITLE="${2:?Usage: create-subtask.sh <parent_task_id> <title>}"
shift 2

PRIORITY="medium"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --priority) PRIORITY="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Get parent task to find project_id
PARENT=$(curl -sf "${MESH_API_URL}/api/v1/tasks/${PARENT_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")
PROJ_ID=$(echo "$PARENT" | jq -r '.project_id')

if [[ -z "$PROJ_ID" || "$PROJ_ID" == "null" ]]; then
  echo "Error: could not resolve project_id from parent task" >&2
  exit 1
fi

BODY=$(jq -n \
  --arg title "$TITLE" \
  --arg priority "$PRIORITY" \
  --arg parent_id "$PARENT_ID" \
  '{title: $title, priority: $priority, parent_task_id: $parent_id}')

curl -sf -X POST "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/tasks" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
