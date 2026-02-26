#!/usr/bin/env bash
# Import workspace configuration from a YAML file.
# Usage: bash import-config.sh <path-to-yaml-file> [workspace_id]
#   If workspace_id is omitted, auto-resolves via /agents/me.
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

YAML_FILE="${1:?Usage: import-config.sh <path-to-yaml-file> [workspace_id]}"
WS_ID="${2:-}"

if [[ ! -f "$YAML_FILE" ]]; then
  echo "Error: file not found: $YAML_FILE" >&2
  exit 1
fi

# Auto-resolve workspace_id if not provided
if [[ -z "$WS_ID" ]]; then
  WS_ID=$(mesh_curl "${MESH_API_URL}/api/v1/agents/me" \
    -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.workspace_id')
  if [[ -z "$WS_ID" || "$WS_ID" == "null" ]]; then
    echo "Error: could not resolve workspace_id from /agents/me" >&2
    exit 1
  fi
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/config/import" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: text/yaml" \
  --data-binary "@${YAML_FILE}" | jq .
