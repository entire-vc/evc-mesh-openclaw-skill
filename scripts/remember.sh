#!/usr/bin/env bash
# Save knowledge to persistent memory (UPSERT by key).
# Usage: bash remember.sh <key> <content> [--scope project|workspace|agent] [--project-id <id>] [--tags tag1,tag2] [--relevance 0.8] [--expires-at 2026-12-31T00:00:00Z] [--source-url <url>]
# Examples:
#   bash remember.sh "api-convention" "All REST responses use envelope {data, meta, error}"
#   bash remember.sh "license-decision" "Apache 2.0" --scope project --tags license,decision
#   bash remember.sh "deploy-info" "Push to main triggers CI" --relevance 0.9 --source-url "https://github.com/org/repo"
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

KEY="${1:?Usage: remember.sh <key> <content> [--scope s] [--project-id id] [--tags t1,t2] [--relevance 0.8] [--expires-at RFC3339] [--source-url url]}"
CONTENT="${2:?Usage: remember.sh <key> <content> [--scope s] [--project-id id] [--tags t1,t2] [--relevance 0.8] [--expires-at RFC3339] [--source-url url]}"
shift 2

SCOPE="project"
PROJECT_ID=""
TAGS="[]"
RELEVANCE=""
EXPIRES_AT=""
SOURCE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --tags)
      # Convert comma-separated to JSON array
      TAGS=$(echo "$2" | jq -R 'split(",")')
      shift 2 ;;
    --relevance) RELEVANCE="$2"; shift 2 ;;
    --expires-at) EXPIRES_AT="$2"; shift 2 ;;
    --source-url) SOURCE_URL="$2"; shift 2 ;;
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

# Add relevance if provided
if [[ -n "$RELEVANCE" ]]; then
  BODY=$(echo "$BODY" | jq --argjson r "$RELEVANCE" '. + {relevance: $r}')
fi

# Add expires_at if provided
if [[ -n "$EXPIRES_AT" ]]; then
  BODY=$(echo "$BODY" | jq --arg ea "$EXPIRES_AT" '. + {expires_at: $ea}')
fi

# Add source_url if provided
if [[ -n "$SOURCE_URL" ]]; then
  BODY=$(echo "$BODY" | jq --arg su "$SOURCE_URL" '. + {source_url: $su}')
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/memories" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
