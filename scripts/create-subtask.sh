#!/usr/bin/env bash
# Create a subtask under a parent task.
# Usage: bash create-subtask.sh <parent_task_id> <title> [options]
#   --priority <p>           Priority: urgent|high|medium|low|none (default: medium)
#   --description <d>        Subtask description
#   --due_date <date>        Due date (ISO 8601, e.g. 2026-03-01T00:00:00Z)
#   --estimated_hours <n>    Estimated hours (number)
#   --labels <l1,l2>         Comma-separated labels
#   --assignee <agent_id>    Assignee agent ID
#   --status <status_id>     Status ID (default: project default)
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PARENT_ID="${1:?Usage: create-subtask.sh <parent_task_id> <title> [options]}"
TITLE="${2:?Usage: create-subtask.sh <parent_task_id> <title>}"
shift 2

PRIORITY="medium"
DESCRIPTION=""
DUE_DATE=""
ESTIMATED_HOURS=""
LABELS=""
ASSIGNEE=""
STATUS_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --priority)        PRIORITY="$2"; shift 2 ;;
    --description)     DESCRIPTION="$2"; shift 2 ;;
    --due_date)        DUE_DATE="$2"; shift 2 ;;
    --estimated_hours) ESTIMATED_HOURS="$2"; shift 2 ;;
    --labels)          LABELS="$2"; shift 2 ;;
    --assignee)        ASSIGNEE="$2"; shift 2 ;;
    --status)          STATUS_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Get parent task to find project_id
PARENT=$(mesh_curl "${MESH_API_URL}/api/v1/tasks/${PARENT_ID}" \
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
  --arg description "$DESCRIPTION" \
  --arg status_id "$STATUS_ID" \
  --arg due_date "$DUE_DATE" \
  --arg estimated_hours "$ESTIMATED_HOURS" \
  --arg labels "$LABELS" \
  --arg assignee "$ASSIGNEE" \
  '{title: $title, priority: $priority, parent_task_id: $parent_id} +
   (if $description != "" then {description: $description} else {} end) +
   (if $status_id != "" then {status_id: $status_id} else {} end) +
   (if $due_date != "" then {due_date: $due_date} else {} end) +
   (if $estimated_hours != "" then {estimated_hours: ($estimated_hours | tonumber)} else {} end) +
   (if $labels != "" then {labels: ($labels | split(","))} else {} end) +
   (if $assignee != "" then {assignee_id: $assignee, assignee_type: "agent"} else {} end)')

mesh_curl -X POST "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/tasks" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
