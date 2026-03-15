#!/usr/bin/env bash
# Delete a memory entry by ID.
# Agents can only delete their own agent-scope memories.
# Usage: bash forget.sh <memory_id>
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

MEMORY_ID="${1:?Usage: forget.sh <memory_id>}"

STATUS=$(mesh_curl_status -X DELETE "${MESH_API_URL}/api/v1/memories/${MEMORY_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")

echo "Deleted (HTTP ${STATUS})"
