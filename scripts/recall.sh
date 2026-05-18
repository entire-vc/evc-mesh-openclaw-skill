#!/usr/bin/env bash
# Search project memory using full-text search.
# Usage: bash recall.sh <query> [--scope project|workspace|agent] [--project-id <id>] [--limit n]
#   [--tags tag1,tag2] [--tags-any t1,t2] [--created-by <uuid>]
#   [--since RFC3339] [--until RFC3339] [--relevance-min 0.5]
#   [--decay] [--order-by created_at:desc|relevance:desc|decayed_relevance:desc]
#   [--include-expired] [--offset n]
# Examples:
#   bash recall.sh "API convention"
#   bash recall.sh "license" --scope project --limit 5
#   bash recall.sh "deploy" --tags deploy,ci --decay --order-by decayed_relevance:desc
#   bash recall.sh "incident" --tags-any incident,error --relevance-min 0.7
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

QUERY="${1:?Usage: recall.sh <query> [--scope s] [--project-id id] [--limit n] [--tags t1,t2] [--tags-any t1,t2] [--created-by uuid] [--since RFC3339] [--until RFC3339] [--relevance-min f] [--decay] [--order-by s] [--include-expired] [--offset n]}"
shift

SCOPE=""
PROJECT_ID=""
LIMIT="10"
TAGS=""
TAGS_ANY=""
CREATED_BY=""
SINCE=""
UNTIL=""
RELEVANCE_MIN=""
DECAY="false"
ORDER_BY=""
INCLUDE_EXPIRED="false"
OFFSET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --project-id) PROJECT_ID="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --tags) TAGS="$2"; shift 2 ;;
    --tags-any) TAGS_ANY="$2"; shift 2 ;;
    --created-by) CREATED_BY="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --until) UNTIL="$2"; shift 2 ;;
    --relevance-min) RELEVANCE_MIN="$2"; shift 2 ;;
    --decay) DECAY="true"; shift ;;
    --order-by) ORDER_BY="$2"; shift 2 ;;
    --include-expired) INCLUDE_EXPIRED="true"; shift ;;
    --offset) OFFSET="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build query string
QS="q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$QUERY'))" 2>/dev/null || echo "$QUERY")&limit=${LIMIT}"
[[ -n "$SCOPE" ]] && QS="${QS}&scope=${SCOPE}"
[[ -n "$PROJECT_ID" ]] && QS="${QS}&project_id=${PROJECT_ID}"

# Add tags (AND filter) — comma-separated → multiple &tags= params
if [[ -n "$TAGS" ]]; then
  IFS=',' read -ra TAG_ARR <<< "$TAGS"
  for tag in "${TAG_ARR[@]}"; do
    QS="${QS}&tags=${tag}"
  done
fi

# Add tags_any (OR filter) — comma-separated → multiple &tags_any= params
if [[ -n "$TAGS_ANY" ]]; then
  IFS=',' read -ra TAG_ANY_ARR <<< "$TAGS_ANY"
  for tag in "${TAG_ANY_ARR[@]}"; do
    QS="${QS}&tags_any=${tag}"
  done
fi

[[ -n "$CREATED_BY" ]] && QS="${QS}&created_by=${CREATED_BY}"
[[ -n "$SINCE" ]] && QS="${QS}&since=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SINCE'))" 2>/dev/null || echo "$SINCE")"
[[ -n "$UNTIL" ]] && QS="${QS}&until=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$UNTIL'))" 2>/dev/null || echo "$UNTIL")"
[[ -n "$RELEVANCE_MIN" ]] && QS="${QS}&relevance_min=${RELEVANCE_MIN}"
[[ "$DECAY" == "true" ]] && QS="${QS}&apply_recency_decay=true"
[[ -n "$ORDER_BY" ]] && QS="${QS}&order_by=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ORDER_BY'))" 2>/dev/null || echo "$ORDER_BY")"
[[ "$INCLUDE_EXPIRED" == "true" ]] && QS="${QS}&include_expired=true"
[[ -n "$OFFSET" ]] && QS="${QS}&offset=${OFFSET}"

mesh_curl "${MESH_API_URL}/api/v1/memories/search?${QS}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
