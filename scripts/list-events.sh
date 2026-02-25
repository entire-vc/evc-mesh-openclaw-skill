#!/usr/bin/env bash
# List events in a project.
# Usage: bash list-events.sh <project_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: list-events.sh <project_id>}"

curl -sf "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/events" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
