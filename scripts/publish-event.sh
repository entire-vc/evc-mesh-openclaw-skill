#!/usr/bin/env bash
# Publish an event to the project event bus.
# Usage: bash publish-event.sh <project_id> <event_type> <subject> <payload_json>
# Event types: summary, context_update, error, custom
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: publish-event.sh <project_id> <event_type> <subject> <payload_json>}"
EVENT_TYPE="${2:?Usage: publish-event.sh <project_id> <event_type> <subject> <payload_json>}"
SUBJECT="${3:?Usage: publish-event.sh <project_id> <event_type> <subject> <payload_json>}"
PAYLOAD="${4:?Usage: publish-event.sh <project_id> <event_type> <subject> <payload_json>}"

BODY=$(jq -n \
  --arg event_type "$EVENT_TYPE" \
  --arg subject "$SUBJECT" \
  --argjson payload "$PAYLOAD" \
  '{event_type: $event_type, subject: $subject, payload: $payload}')

mesh_curl -X POST "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/events" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
