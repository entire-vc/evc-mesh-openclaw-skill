#!/usr/bin/env bash
# List task statuses for a project. Shows ID, name, slug, category, color, position.
# Usage: bash list-statuses.sh <project_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: list-statuses.sh <project_id>}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/statuses" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
