#!/usr/bin/env bash
# Get workflow rules for a project including allowed transitions and caller permissions.
# Usage: bash get-workflow-rules.sh <project_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: get-workflow-rules.sh <project_id>}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/rules/workflow" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
