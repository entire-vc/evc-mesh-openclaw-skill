#!/usr/bin/env bash
# Save knowledge to persistent memory (UPSERT by key).
# Usage: bash remember.sh <key> <content> [--scope project|workspace|agent] [--project-id <id>] [--tags tag1,tag2]
# Examples:
#   bash remember.sh "api-convention" "All REST responses use envelope {data, meta, error}"
#   bash remember.sh "license-decision" "Apache 2.0" --scope project --tags license,decision
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

KEY="${1:?Usage: remember.sh <key> <content> [--scope s] [--project-id id] [--tags t1,t2]}"
CONTENT="${2:?Usage: remember.sh <key> <content> [--scope s] [--project-id id] [--tags t1,t2]}"
shift 2

SCOPE="project"
PROJECT_ID=""
TAGS="[]"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --tags)
      # Convert comma-separated to JSON array
      TAGS=$(echo "$2" | jq -R 'split(",")')
      shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n \
  --arg key "$KEY" \
  --arg content "$CONTENT" \
  --arg scope "$SCOPE" \
  --arg source_type "agent" \
  --argjson tags "$TAGS" \
  '{key: $key, content: $content, scope: $scope, source_type: $source_type, tags: $tags}')

# Add project_id if provided
if [[ -n "$PROJECT_ID" ]]; then
  BODY=$(echo "$BODY" | jq --arg pid "$PROJECT_ID" '. + {project_id: $pid}')
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/memories" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
