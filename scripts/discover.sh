#!/usr/bin/env bash
# Discover workspace, projects, and statuses for the current agent.
# Outputs env-friendly variables for use in other scripts.
# Usage: bash discover.sh [--export] [--json]
#   --export   Print as export statements (source-able)
#   --json     Print as JSON object
#   (default)  Print human-readable summary
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

FORMAT="text"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --export) FORMAT="export"; shift ;;
    --json)   FORMAT="json"; shift ;;
    *)        echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Step 1: Get agent profile -> workspace_id
AGENT=$(mesh_curl "${MESH_API_URL}/api/v1/agents/me" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")

AGENT_ID=$(echo "$AGENT" | jq -r '.id')
AGENT_NAME=$(echo "$AGENT" | jq -r '.name')
WS_ID=$(echo "$AGENT" | jq -r '.workspace_id')

if [[ -z "$WS_ID" || "$WS_ID" == "null" ]]; then
  echo "Error: could not resolve workspace_id from /agents/me" >&2
  exit 1
fi

# Step 2: List projects
PROJECTS=$(mesh_curl "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/projects" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")

PROJECT_COUNT=$(echo "$PROJECTS" | jq '.total_count // (.items | length)')

# Step 3: For each project, get statuses
ENRICHED=$(echo "$PROJECTS" | jq -c '.items[]' | while read -r proj; do
  PROJ_ID=$(echo "$proj" | jq -r '.id')
  PROJ_NAME=$(echo "$proj" | jq -r '.name')
  PROJ_SLUG=$(echo "$proj" | jq -r '.slug')

  STATUSES=$(mesh_curl "${MESH_API_URL}/api/v1/projects/${PROJ_ID}/statuses" \
    -H "X-Agent-Key: ${MESH_AGENT_KEY}" 2>/dev/null || echo '[]')

  echo "$proj" | jq --argjson statuses "$STATUSES" '. + {statuses: $statuses}'
done | jq -s '.')

# Output
case "$FORMAT" in
  export)
    echo "export MESH_AGENT_ID=\"${AGENT_ID}\""
    echo "export MESH_AGENT_NAME=\"${AGENT_NAME}\""
    echo "export MESH_WORKSPACE_ID=\"${WS_ID}\""
    echo "$ENRICHED" | jq -r '.[0] // empty | "export MESH_PROJECT_ID=\"\(.id)\"\nexport MESH_PROJECT_SLUG=\"\(.slug)\""'
    echo "# Projects: ${PROJECT_COUNT}"
    echo "$ENRICHED" | jq -r '.[] | "# Project: \(.name) (\(.id))"'
    echo "$ENRICHED" | jq -r '.[0] // empty | .statuses[]? | "# Status: \(.name) [\(.category)] = \(.id)"'
    ;;
  json)
    jq -n \
      --arg agent_id "$AGENT_ID" \
      --arg agent_name "$AGENT_NAME" \
      --arg workspace_id "$WS_ID" \
      --argjson projects "$ENRICHED" \
      '{agent_id: $agent_id, agent_name: $agent_name, workspace_id: $workspace_id, projects: $projects}'
    ;;
  text)
    echo "Agent:     ${AGENT_NAME} (${AGENT_ID})"
    echo "Workspace: ${WS_ID}"
    echo "Projects:  ${PROJECT_COUNT}"
    echo ""
    echo "$ENRICHED" | jq -r '.[] | "  \(.name) [\(.slug)]  \(.id)\n    Statuses:"'
    echo "$ENRICHED" | jq -r '.[] | .statuses[]? | "      \(.name) [\(.category)] = \(.id)"'
    ;;
esac
