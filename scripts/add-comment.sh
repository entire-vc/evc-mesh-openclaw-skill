#!/usr/bin/env bash
# Add a comment to a task.
# Usage: bash add-comment.sh <task_id> <content>
#        echo "content" | bash add-comment.sh <task_id> -
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: add-comment.sh <task_id> <content>}"
CONTENT="${2:?Usage: add-comment.sh <task_id> <content>}"

if [[ "$CONTENT" == "-" ]]; then
  CONTENT=$(cat)
fi

BODY=$(jq -n --arg body "$CONTENT" '{body: $body}')

mesh_curl -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/comments" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
