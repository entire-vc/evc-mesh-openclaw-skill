#!/usr/bin/env bash
# Search project memory using full-text search.
# Usage: bash recall.sh <query> [--scope project|workspace|agent] [--project-id <id>] [--limit n]
# Examples:
#   bash recall.sh "API convention"
#   bash recall.sh "license" --scope project --limit 5
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

QUERY="${1:?Usage: recall.sh <query> [--scope s] [--project-id id] [--limit n]}"
shift

SCOPE=""
PROJECT_ID=""
LIMIT="10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build query string
QS="q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))" 2>/dev/null || echo "$QUERY")&limit=${LIMIT}"
[[ -n "$SCOPE" ]] && QS="${QS}&scope=${SCOPE}"
[[ -n "$PROJECT_ID" ]] && QS="${QS}&project_id=${PROJECT_ID}"

mesh_curl "${MESH_API_URL}/api/v1/memories/search?${QS}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
