#!/usr/bin/env bash
# Set the agent's callback URL for push notifications.
# When set, Mesh will POST task events (assigned, created, status_changed) to this URL.
# Usage: bash set-callback-url.sh <url>
#   url — the callback URL (use "" to clear)
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

URL="${1:?Usage: set-callback-url.sh <url>}"

# Auto-resolve agent_id from /agents/me
AGENT_ID=$(mesh_curl -X GET "${MESH_API_URL}/api/v1/agents/me" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.id')
if [[ -z "$AGENT_ID" || "$AGENT_ID" == "null" ]]; then
  echo "Error: could not resolve agent_id from /agents/me" >&2
  exit 1
fi

BODY=$(jq -n --arg url "$URL" '{callback_url: $url}')

mesh_curl -X PATCH "${MESH_API_URL}/api/v1/agents/${AGENT_ID}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq '{id, name, callback_url}'
