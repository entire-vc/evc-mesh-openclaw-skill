#!/usr/bin/env bash
# List projects in a workspace.
# Usage: bash list-projects.sh [workspace_id]
#   If workspace_id is omitted, auto-resolves via /agents/me.
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

WS_ID="${1:-}"

# Auto-resolve workspace_id if not provided
if [[ -z "$WS_ID" ]]; then
  WS_ID=$(mesh_curl "${MESH_API_URL}/api/v1/agents/me" \
    -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.workspace_id')
  if [[ -z "$WS_ID" || "$WS_ID" == "null" ]]; then
    echo "Error: could not resolve workspace_id from /agents/me" >&2
    exit 1
  fi
fi

mesh_curl "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/projects" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
