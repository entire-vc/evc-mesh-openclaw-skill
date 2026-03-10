#!/usr/bin/env bash
# Release a previously checked-out task.
# Usage: bash release-task.sh <task_id> <checkout_token>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: release-task.sh <task_id> <checkout_token>}"
TOKEN="${2:?Usage: release-task.sh <task_id> <checkout_token>}"

BODY=$(jq -n --arg token "$TOKEN" '{checkout_token: $token}')

mesh_curl -X DELETE "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/checkout" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY"

echo '{"status": "released"}'
