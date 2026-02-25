#!/usr/bin/env bash
# Get project details by ID.
# Usage: bash get-project.sh <project_id>
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: get-project.sh <project_id>}"

curl -sf "${MESH_API_URL}/api/v1/projects/${PROJ_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
