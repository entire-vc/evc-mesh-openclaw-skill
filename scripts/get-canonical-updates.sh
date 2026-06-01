#!/usr/bin/env bash
# Fetch canonical decisions broadcast since a given time (F2 C3 — ACP step 6).
# Call at session start to catch up on Pavel directives since your last session.
# Returns only privacy:public records targeted at you or all agents.
#
# Usage: bash get-canonical-updates.sh [--since RFC3339] [--agent slug] [--scope project_id]
# Examples:
#   bash get-canonical-updates.sh --agent linus
#   bash get-canonical-updates.sh --since 2026-06-01T00:00:00Z --agent bill
#   bash get-canonical-updates.sh --scope 44797081-489d-4d10-8972-a19db6b03600 --agent howard
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

SINCE=""
AGENT=""
SCOPE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --agent) AGENT="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

QS=""
[[ -n "$SINCE" ]] && QS="${QS:+${QS}&}since=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$SINCE'))" 2>/dev/null || echo "$SINCE")"
[[ -n "$AGENT" ]] && QS="${QS:+${QS}&}agent=${AGENT}"
[[ -n "$SCOPE" ]] && QS="${QS:+${QS}&}scope=${SCOPE}"

URL="${MESH_API_URL}/api/v1/canonical_updates"
[[ -n "$QS" ]] && URL="${URL}?${QS}"

mesh_curl "$URL" -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
