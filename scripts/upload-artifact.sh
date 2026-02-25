#!/usr/bin/env bash
# Upload an artifact to a task (multipart form upload).
# Usage: bash upload-artifact.sh <task_id> <name> <type> <file_path>
#        echo "content" | bash upload-artifact.sh <task_id> <name> <type> -
# Types: code, log, report, file, data
set -euo pipefail

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

TASK_ID="${1:?Usage: upload-artifact.sh <task_id> <name> <type> <file_path>}"
NAME="${2:?Usage: upload-artifact.sh <task_id> <name> <type> <file_path>}"
ATYPE="${3:?Usage: upload-artifact.sh <task_id> <name> <type> <file_path>}"
FILE_OR_STDIN="${4:?Usage: upload-artifact.sh <task_id> <name> <type> <file_path>}"

if [[ "$FILE_OR_STDIN" == "-" ]]; then
  # Read from stdin into a temp file
  TMPFILE=$(mktemp)
  trap 'rm -f "$TMPFILE"' EXIT
  cat > "$TMPFILE"
  FILE_OR_STDIN="$TMPFILE"
fi

if [[ ! -f "$FILE_OR_STDIN" ]]; then
  echo "Error: file not found: $FILE_OR_STDIN" >&2
  exit 1
fi

curl -sf -X POST "${MESH_API_URL}/api/v1/tasks/${TASK_ID}/artifacts" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -F "name=${NAME}" \
  -F "artifact_type=${ATYPE}" \
  -F "file=@${FILE_OR_STDIN}" | jq .
