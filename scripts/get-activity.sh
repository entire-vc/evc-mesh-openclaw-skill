#!/usr/bin/env bash
# Get activity log for a task (comments, status changes, artifacts).
# Usage: bash get-activity.sh <task_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: get-activity.sh <task_id>}"

mesh_curl "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/activity" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
