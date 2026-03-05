#!/usr/bin/env bash
# Trigger a recurring schedule immediately, creating a task instance now.
# Usage: bash trigger-recurring-now.sh --schedule-id <id>
#   --schedule-id <id>   Recurring schedule UUID (required)
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

SCHEDULE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --schedule-id)   SCHEDULE_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

: "${SCHEDULE_ID:?--schedule-id is required}"

mesh_curl -X POST "${MESH_API_URL}/api/v1/recurring/${SCHEDULE_ID}/trigger" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}' | jq .
