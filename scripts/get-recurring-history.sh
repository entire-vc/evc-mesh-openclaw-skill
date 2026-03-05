#!/usr/bin/env bash
# Get the instance history for a recurring task schedule.
# Usage: bash get-recurring-history.sh --schedule-id <id> [options]
#   --schedule-id <id>   Recurring schedule UUID (required)
#   --limit <n>          Number of history entries to return (default: 10)
#   --page <n>           Page number for pagination (default: 1)
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

SCHEDULE_ID=""
LIMIT="10"
PAGE="1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --schedule-id)   SCHEDULE_ID="$2"; shift 2 ;;
    --limit)         LIMIT="$2"; shift 2 ;;
    --page)          PAGE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

: "${SCHEDULE_ID:?--schedule-id is required}"

PARAMS="limit=${LIMIT}&page=${PAGE}"

mesh_curl "${MESH_API_URL}/api/v1/recurring/${SCHEDULE_ID}/history?${PARAMS}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
