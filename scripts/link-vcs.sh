#!/usr/bin/env bash
# Link a VCS reference (PR, commit, branch) to a task.
# Usage: bash link-vcs.sh <task_id> <type> <external_id> <url> [--title <t>] [--provider github|gitlab]
# Types: pr, commit, branch
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: link-vcs.sh <task_id> <type> <external_id> <url> [--title t] [--provider github|gitlab]}"
LINK_TYPE="${2:?Usage: link-vcs.sh <task_id> <type> <external_id> <url>}"
EXTERNAL_ID="${3:?Usage: link-vcs.sh <task_id> <type> <external_id> <url>}"
URL="${4:?Usage: link-vcs.sh <task_id> <type> <external_id> <url>}"
shift 4

TITLE=""
PROVIDER="github"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --provider) PROVIDER="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

BODY=$(jq -n \
  --arg link_type "$LINK_TYPE" \
  --arg external_id "$EXTERNAL_ID" \
  --arg url "$URL" \
  --arg title "$TITLE" \
  --arg provider "$PROVIDER" \
  '{link_type: $link_type, external_id: $external_id, url: $url, provider: $provider} + (if $title != "" then {title: $title} else {} end)')

curl -sf -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/vcs-links" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
