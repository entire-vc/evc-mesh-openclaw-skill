#!/usr/bin/env bash
# List tasks in a project with optional filters.
# Usage: bash list-tasks.sh <project_id> [--status <status_id>] [--assignee me] [--priority <p>]
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJ_ID="${1:?Usage: list-tasks.sh <project_id> [--status <id>] [--assignee me] [--priority <p>]}"
shift

PARAMS="page_size=200"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      PARAMS="${PARAMS}&status_id=${2}"
      shift 2
      ;;
    --assignee)
      PARAMS="${PARAMS}&assignee=${2}"
      shift 2
      ;;
    --priority)
      PARAMS="${PARAMS}&priority=${2}"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/tasks?${PARAMS}" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq .
