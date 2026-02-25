#!/usr/bin/env bash
# Post a project status update.
# Usage: bash post-update.sh <project_id> <title> <summary> [--status on_track|at_risk|off_track|completed]
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: post-update.sh <project_id> <title> <summary> [--status s]}"
TITLE="${2:?Usage: post-update.sh <project_id> <title> <summary>}"
SUMMARY="${3:?Usage: post-update.sh <project_id> <title> <summary>}"
shift 3

STATUS="on_track"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) STATUS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n \
  --arg title "$TITLE" \
  --arg summary "$SUMMARY" \
  --arg status "$STATUS" \
  '{title: $title, summary: $summary, status: $status}')

curl -sf -X POST "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/updates" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
