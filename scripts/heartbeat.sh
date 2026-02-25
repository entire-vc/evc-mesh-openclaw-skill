#!/usr/bin/env bash
# Send agent heartbeat to EVC Mesh.
# Usage: bash heartbeat.sh <status>
# Status: online | busy | error
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL (e.g. https://mesh.entire.host)}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY (e.g. agk_workspace_...)}"

STATUS="${1:?Usage: heartbeat.sh <online|busy|error>}"

curl -sf -X POST "${MESH_API_URL}/api/v1/agents/heartbeat" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"status\": \"${STATUS}\"}"
