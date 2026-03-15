#!/usr/bin/env bash
# Download an artifact's content.
# Usage: bash download-artifact.sh <artifact_id> [--output <file>]
# Without --output, prints content to stdout.
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

ARTIFACT_ID="${1:?Usage: download-artifact.sh <artifact_id> [--output <file>]}"
shift

OUTPUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output|-o) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Get download URL (presigned S3 URL)
DOWNLOAD_URL=$(mesh_curl "${MESH_API_URL}/api/v1/artifacts/${ARTIFACT_ID}/download" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.url // empty')

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "Error: no download URL returned" >&2
  exit 1
fi

# Download content
if [[ -n "$OUTPUT" ]]; then
  curl -sSL -o "$OUTPUT" "$DOWNLOAD_URL"
  echo "Downloaded to $OUTPUT"
else
  curl -sSL "$DOWNLOAD_URL"
fi
