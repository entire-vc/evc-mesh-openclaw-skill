#!/usr/bin/env bash
# Export workspace configuration as YAML.
# Usage: bash export-config.sh [workspace_id] [--output <file.yaml>]
#   If workspace_id is omitted, auto-resolves via /agents/me.
#   If --output is omitted, prints YAML to stdout.
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

WS_ID=""
OUTPUT_FILE=""

# Parse args: first positional (non-flag) is workspace_id
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$WS_ID" ]]; then
        WS_ID="$1"
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      shift
      ;;
  esac
done

# Auto-resolve workspace_id if not provided
if [[ -z "$WS_ID" ]]; then
  WS_ID=$(mesh_curl "${MESH_API_URL}/api/v1/agents/me" \
    -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.workspace_id')
  if [[ -z "$WS_ID" || "$WS_ID" == "null" ]]; then
    echo "Error: could not resolve workspace_id from /agents/me" >&2
    exit 1
  fi
fi

YAML_CONTENT=$(mesh_curl "${MESH_API_URL}/api/v1/workspaces/${WS_ID}/config/export" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}")

if [[ -n "$OUTPUT_FILE" ]]; then
  echo "$YAML_CONTENT" > "$OUTPUT_FILE"
  echo "Config exported to $OUTPUT_FILE"
else
  echo "$YAML_CONTENT"
fi
