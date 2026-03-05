#!/usr/bin/env bash
# List recurring task schedules for a project.
# Usage: bash list-recurring-schedules.sh --project-id <id> [options]
#   --project-id <id>    Project UUID (required)
#   --active-only        Return only active schedules (default: true)
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJECT_ID=""
ACTIVE_ONLY="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)    PROJECT_ID="$2"; shift 2 ;;
    --active-only)   ACTIVE_ONLY="true"; shift ;;
    --no-active-only) ACTIVE_ONLY="false"; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

: "${PROJECT_ID:?--project-id is required}"

PARAMS="active_only=${ACTIVE_ONLY}"

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJECT_ID}/recurring?${PARAMS}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
