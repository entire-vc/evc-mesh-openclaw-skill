#!/usr/bin/env bash
# Get effective assignment rules for a project (workspace + project merged with source annotations).
# Usage: bash get-assignment-rules.sh <project_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: get-assignment-rules.sh <project_id>}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/rules/assignment" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
