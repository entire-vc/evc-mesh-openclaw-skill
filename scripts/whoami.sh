#!/usr/bin/env bash
# Get current agent profile (ID, workspace, name).
# Usage: bash whoami.sh
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

curl -sf "${MESH_API_URL}/api/v1/agents/me" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
