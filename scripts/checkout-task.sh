#!/usr/bin/env bash
# Exclusively lock a task for working. Returns a checkout_token.
# Other agents cannot checkout the same task until released or TTL expires.
# Usage: bash checkout-task.sh <task_id> [ttl_minutes]
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: checkout-task.sh <task_id> [ttl_minutes]}"
TTL="${2:-15}"

BODY=$(jq -n --argjson ttl "$TTL" '{ttl_minutes: $ttl}')

mesh_curl -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/checkout" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
