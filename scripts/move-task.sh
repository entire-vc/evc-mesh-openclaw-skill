#!/usr/bin/env bash
# Move task to a different status.
# Usage: bash move-task.sh <task_id> <status_id> [--assignee <agent_or_user_id>] [--assignee-type agent|user] [--comment "text"]
# On move to 'review', task auto-reassigns to creator unless --assignee is provided.
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: move-task.sh <task_id> <status_id> [--assignee id] [--assignee-type agent|user] [--comment text]}"
STATUS_ID="${2:?Usage: move-task.sh <task_id> <status_id> [--assignee id] [--assignee-type agent|user] [--comment text]}"
shift 2

ASSIGNEE_ID=""
ASSIGNEE_TYPE="agent"
COMMENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assignee) ASSIGNEE_ID="$2"; shift 2 ;;
    --assignee-type) ASSIGNEE_TYPE="$2"; shift 2 ;;
    --comment) COMMENT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n --arg status_id "$STATUS_ID" '{status_id: $status_id}')

if [[ -n "$ASSIGNEE_ID" ]]; then
  BODY=$(echo "$BODY" | jq --arg aid "$ASSIGNEE_ID" --arg atype "$ASSIGNEE_TYPE" \
    '. + {assignee_id: $aid, assignee_type: $atype}')
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/move" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .

# Add comment if provided (best-effort, don't fail the move)
if [[ -n "$COMMENT" ]]; then
  CBODY=$(jq -n --arg body "$COMMENT" '{body: $body}')
  mesh_curl -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/comments" \
    -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
    -H "Content-Type: application/json" \
    -d "$CBODY" > /dev/null 2>&1 || true
fi
