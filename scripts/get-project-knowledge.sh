#!/usr/bin/env bash
# Get all accumulated project knowledge (workspace + project memories).
# Call at session start to load context.
# Usage: bash get-project-knowledge.sh <project_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJECT_ID="${1:?Usage: get-project-knowledge.sh <project_id>}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJECT_ID}/knowledge" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
