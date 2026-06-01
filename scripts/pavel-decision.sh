#!/usr/bin/env bash
# Record a Pavel directive as a canonical decision (F2 C3).
# Stored in memories with kind:canonical-decision tags; broadcast via propagate_to.
# privacy:private decisions are stored but hidden from get-canonical-updates.sh.
#
# Usage: bash pavel-decision.sh <text> <summary> [--propagate-to slug1,slug2|all]
#   [--scope <project_id>] [--privacy public|private]
# Examples:
#   bash pavel-decision.sh "Use TypeScript for all new frontend code" "typescript-frontend"
#   bash pavel-decision.sh "Freeze non-critical merges until Friday" "merge-freeze-2026-06-06" \
#     --propagate-to all
#   bash pavel-decision.sh "Auth key rotation to monthly" "auth-key-rotation" \
#     --propagate-to linus,bill --scope 44797081-489d-4d10-8972-a19db6b03600
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TEXT="${1:?Usage: pavel-decision.sh <text> <summary> [--propagate-to slugs|all] [--scope project_id] [--privacy public|private]}"
SUMMARY="${2:?Usage: pavel-decision.sh <text> <summary> [--propagate-to slugs|all] [--scope project_id] [--privacy public|private]}"
shift 2

PROPAGATE_TO=""
SCOPE=""
PRIVACY="public"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --propagate-to) PROPAGATE_TO="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --privacy) PRIVACY="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build slug: lowercase, non-alnum → dash, collapse dashes, max 50 chars
SLUG=$(echo "$SUMMARY" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-\+/-/g; s/^-//; s/-$//' | cut -c1-50)
DAY=$(date -u +%Y-%m-%d)
KEY="canonical-decision:${DAY}:${SLUG}"

# Build tags array
TAGS='["kind:canonical-decision","owner:riker","source:pavel-tg","privacy:'"${PRIVACY}"'"]'

if [[ -n "$PROPAGATE_TO" ]]; then
  IFS=',' read -ra TARGETS <<< "$PROPAGATE_TO"
  for target in "${TARGETS[@]}"; do
    target="${target// /}"
    [[ -n "$target" ]] && TAGS=$(echo "$TAGS" | jq --arg t "propagate_to:${target}" '. + [$t]')
  done
fi

BODY=$(jq -n \
  --arg key "$KEY" \
  --arg content "$TEXT" \
  --arg scope "workspace" \
  --argjson tags "$TAGS" \
  '{key: $key, content: $content, scope: $scope, source_type: "human", tags: $tags}')

if [[ -n "$SCOPE" ]]; then
  BODY=$(echo "$BODY" | jq --arg pid "$SCOPE" '. + {project_id: $pid, scope: "project"}')
fi

mesh_curl -X POST "${MESH_API_URL}/api/v1/memories" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
