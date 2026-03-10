#!/usr/bin/env bash
# Extend the checkout TTL for a task you have checked out.
# Usage: bash extend-checkout.sh <task_id> <checkout_token> [ttl_minutes]
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: extend-checkout.sh <task_id> <checkout_token> [ttl_minutes]}"
TOKEN="${2:?Usage: extend-checkout.sh <task_id> <checkout_token> [ttl_minutes]}"
TTL="${3:-15}"

BODY=$(jq -n --arg token "$TOKEN" --argjson ttl "$TTL" '{checkout_token: $token, ttl_minutes: $ttl}')

mesh_curl -X PATCH "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/checkout" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
