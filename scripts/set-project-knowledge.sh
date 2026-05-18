#!/usr/bin/env bash
# Write a structured fact to project knowledge (UPSERT by key).
# Visible via get-project-knowledge.sh and get_project_knowledge MCP tool.
# Usage: bash set-project-knowledge.sh <project-id> <key> <value> [--category <cat>] [--tags tag1,tag2] [--source-url <url>]
# Examples:
#   bash set-project-knowledge.sh "$PROJECT_ID" "deploy-url" "https://mesh.entire.host" --category deploy
#   bash set-project-knowledge.sh "$PROJECT_ID" "stack-convention" "Go 1.22 + Echo + PostgreSQL 16" --category stack
#   bash set-project-knowledge.sh "$PROJECT_ID" "ci-trigger" "Push to main triggers CI/CD" --category gotchas --source-url "https://github.com/org/repo/actions"
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJECT_ID="${1:?Usage: set-project-knowledge.sh <project-id> <key> <value> [--category cat] [--tags t1,t2] [--source-url url]}"
KEY="${2:?Usage: set-project-knowledge.sh <project-id> <key> <value> [--category cat] [--tags t1,t2] [--source-url url]}"
VALUE="${3:?Usage: set-project-knowledge.sh <project-id> <key> <value> [--category cat] [--tags t1,t2] [--source-url url]}"
shift 3

CATEGORY=""
TAGS="[]"
SOURCE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --category) CATEGORY="$2"; shift 2 ;;
    --tags)
      TAGS=$(echo "$2" | jq -R 'split(",")')
      shift 2 ;;
    --source-url) SOURCE_URL="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n \
  --arg key "$KEY" \
  --arg value "$VALUE" \
  --arg source_type "agent" \
  --argjson tags "$TAGS" \
  '{key: $key, value: $value, source_type: $source_type, tags: $tags}')

if [[ -n "$CATEGORY" ]]; then
  BODY=$(echo "$BODY" | jq --arg cat "$CATEGORY" '. + {category: $cat}')
fi

if [[ -n "$SOURCE_URL" ]]; then
  BODY=$(echo "$BODY" | jq --arg su "$SOURCE_URL" '. + {source_url: $su}')
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/projects/${PROJECT_ID}/knowledge" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
