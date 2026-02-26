#!/usr/bin/env bash
# Update the calling agent's profile fields.
# Usage: bash update-agent-profile.sh [options]
#   --role <role>                  Agent role (e.g. developer, reviewer, tester)
#   --capabilities <go,react>      Comma-separated capability strings
#   --zone <zone>                  Responsibility zone (e.g. Backend, Frontend)
#   --escalation-to <agent_id>     Agent ID or name to escalate issues to
#   --accepts-from <id1,id2>       Comma-separated agent IDs this agent accepts tasks from
#   --max-tasks <n>                Maximum number of concurrent tasks
#   --hours <description>          Working hours (e.g. "24/7", "9-17 UTC")
#   --description <text>           Human-readable description of the agent's purpose
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

ROLE=""
CAPABILITIES=""
ZONE=""
ESCALATION_TO=""
ACCEPTS_FROM=""
MAX_TASKS=""
HOURS=""
DESCRIPTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role)           ROLE="$2"; shift 2 ;;
    --capabilities)   CAPABILITIES="$2"; shift 2 ;;
    --zone)           ZONE="$2"; shift 2 ;;
    --escalation-to)  ESCALATION_TO="$2"; shift 2 ;;
    --accepts-from)   ACCEPTS_FROM="$2"; shift 2 ;;
    --max-tasks)      MAX_TASKS="$2"; shift 2 ;;
    --hours)          HOURS="$2"; shift 2 ;;
    --description)    DESCRIPTION="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Auto-resolve agent_id from /agents/me
AGENT_ID=$(mesh_curl "${MESH_API_URL}/api/v1/agents/me" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" | jq -r '.id')
if [[ -z "$AGENT_ID" || "$AGENT_ID" == "null" ]]; then
  echo "Error: could not resolve agent_id from /agents/me" >&2
  exit 1
fi

BODY=$(jq -n \
  --arg role "$ROLE" \
  --arg capabilities "$CAPABILITIES" \
  --arg responsibility_zone "$ZONE" \
  --arg escalation_to "$ESCALATION_TO" \
  --arg accepts_from "$ACCEPTS_FROM" \
  --arg max_concurrent_tasks "$MAX_TASKS" \
  --arg working_hours "$HOURS" \
  --arg description "$DESCRIPTION" \
  '(if $role != "" then {role: $role} else {} end) +
   (if $capabilities != "" then {capabilities: ($capabilities | split(","))} else {} end) +
   (if $responsibility_zone != "" then {responsibility_zone: $responsibility_zone} else {} end) +
   (if $escalation_to != "" then {escalation_to: $escalation_to} else {} end) +
   (if $accepts_from != "" then {accepts_from: ($accepts_from | split(","))} else {} end) +
   (if $max_concurrent_tasks != "" then {max_concurrent_tasks: ($max_concurrent_tasks | tonumber)} else {} end) +
   (if $working_hours != "" then {working_hours: $working_hours} else {} end) +
   (if $description != "" then {description: $description} else {} end)')

if [[ "$BODY" == "{}" ]]; then
  echo "Error: no profile fields provided. Use --role, --capabilities, --zone, --hours, or --description." >&2
  exit 1
fi

mesh_curl -X PUT "${MESH_API_URL}/api/v1/agents/${AGENT_ID}/profile" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
