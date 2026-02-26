#!/usr/bin/env bash
# Long-poll for new task assignments. Blocks until a task is assigned or timeout.
# Usage: bash poll-tasks.sh [timeout_seconds]
#   timeout_seconds  — max wait time (default 30, max 120)
# Returns: {"tasks": [...], "count": N, "changed": true/false}
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TIMEOUT="${1:-30}"

mesh_curl -X GET "${MESH_API_URL}/api/v1/agents/me/tasks/poll?timeout=${TIMEOUT}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
