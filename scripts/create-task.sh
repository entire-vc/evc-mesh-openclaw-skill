#!/usr/bin/env bash
# Create a new task in a project.
# Usage: bash create-task.sh <project_id> <title> [--priority <p>] [--description <d>] [--status <status_id>]
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: create-task.sh <project_id> <title> [--priority p] [--description d]}"
TITLE="${2:?Usage: create-task.sh <project_id> <title>}"
shift 2

PRIORITY="medium"
DESCRIPTION=""
STATUS_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --priority)   PRIORITY="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --status)     STATUS_ID="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n \
  --arg title "$TITLE" \
  --arg priority "$PRIORITY" \
  --arg description "$DESCRIPTION" \
  --arg status_id "$STATUS_ID" \
  '{title: $title, priority: $priority} +
   (if $description != "" then {description: $description} else {} end) +
   (if $status_id != "" then {status_id: $status_id} else {} end)')

curl -sf -X POST "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/tasks" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
