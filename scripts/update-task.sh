#!/usr/bin/env bash
# Update task fields.
# Usage: bash update-task.sh <task_id> [--title <t>] [--priority <p>] [--description <d>]
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: update-task.sh <task_id> [--title t] [--priority p] [--description d]}"
shift

FIELDS="{}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)       FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {title: $v}'); shift 2 ;;
    --priority)    FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {priority: $v}'); shift 2 ;;
    --description) FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {description: $v}'); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

curl -sf -X PATCH "${MESH_API_URL}/api/v1/tasks/${TASK_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$FIELDS" | jq .
