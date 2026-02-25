#!/usr/bin/env bash
# List projects in a workspace.
# Usage: bash list-projects.sh <workspace_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

WS_ID="${1:?Usage: list-projects.sh <workspace_id>}"

curl -sf "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/projects" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
