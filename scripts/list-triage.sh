#!/usr/bin/env bash
# List tasks in the triage inbox (unrouted tasks awaiting assignment).
# Usage: bash list-triage.sh <workspace_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

WS_ID="${1:?Usage: list-triage.sh <workspace_id>}"

mesh_curl "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/triage?per_page=50" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
