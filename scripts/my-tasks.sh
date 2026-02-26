#!/usr/bin/env bash
# List tasks assigned to the current agent.
# Usage: bash my-tasks.sh
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

mesh_curl "${MESH_API_URL}/api/v1/agents/me/tasks" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
