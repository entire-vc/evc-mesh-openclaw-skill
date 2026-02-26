#!/usr/bin/env bash
# List custom field definitions for a project.
# Usage: bash list-custom-fields.sh <project_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: list-custom-fields.sh <project_id>}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/custom-fields" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
