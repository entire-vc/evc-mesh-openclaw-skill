#!/usr/bin/env bash
# Update task fields.
# Usage: bash update-task.sh <task_id> [options]
#   --title <t>              New title
#   --priority <p>           Priority: urgent|high|medium|low|none
#   --description <d>        New description
#   --due_date <date>        Due date (ISO 8601, e.g. 2026-03-01T00:00:00Z)
#   --estimated_hours <n>    Estimated hours (number)
#   --labels <l1,l2>         Comma-separated labels
#   --assignee <agent_id>    Assignee agent ID
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: update-task.sh <task_id> [--title t] [--priority p] [--description d] [--due_date d] ...}"
shift

FIELDS="{}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)           FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {title: $v}'); shift 2 ;;
    --priority)        FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {priority: $v}'); shift 2 ;;
    --description)     FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {description: $v}'); shift 2 ;;
    --due_date)        FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {due_date: $v}'); shift 2 ;;
    --estimated_hours) FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {estimated_hours: ($v | tonumber)}'); shift 2 ;;
    --labels)          FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {labels: ($v | split(","))}'); shift 2 ;;
    --assignee)        FIELDS=$(echo "$FIELDS" | jq --arg v "$2" '. + {assignee_id: $v, assignee_type: "agent"}'); shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

mesh_curl -X PATCH "${MESH_API_URL}/api/v1/tasks/${TASK_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$FIELDS" | jq .
