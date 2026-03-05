#!/usr/bin/env bash
# Create a recurring task schedule for a project.
# Usage: bash create-recurring-schedule.sh --project-id <id> --title-template <t> --frequency <f> [options]
#   --project-id <id>              Project UUID (required)
#   --title-template <t>           Title template string (required)
#   --frequency <f>                Frequency: daily|weekly|monthly|custom (required)
#   --description-template <d>     Description template string
#   --cron-expr <expr>             Cron expression (required when frequency=custom)
#   --timezone <tz>                Timezone (e.g. UTC, America/New_York; default: UTC)
#   --assignee-id <id>             Assignee UUID
#   --assignee-type <type>         Assignee type: agent|user (default: agent)
#   --priority <p>                 Priority: urgent|high|medium|low|none (default: medium)
#   --labels <l1,l2>               Comma-separated labels
#   --starts-at <datetime>         Schedule start datetime (ISO 8601)
#   --ends-at <datetime>           Schedule end datetime (ISO 8601)
#   --max-instances <n>            Maximum number of task instances to create
set -euo pipefail

source "$(dirname "$0")/_lib.sh"

: "${MESH_API_URL:?Set MESH_API_URL}"
: "${MESH_AGENT_KEY:?Set MESH_AGENT_KEY}"

PROJECT_ID=""
TITLE_TEMPLATE=""
FREQUENCY=""
DESCRIPTION_TEMPLATE=""
CRON_EXPR=""
TIMEZONE="UTC"
ASSIGNEE_ID=""
ASSIGNEE_TYPE="agent"
PRIORITY="medium"
LABELS=""
STARTS_AT=""
ENDS_AT=""
MAX_INSTANCES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)             PROJECT_ID="$2"; shift 2 ;;
    --title-template)         TITLE_TEMPLATE="$2"; shift 2 ;;
    --frequency)              FREQUENCY="$2"; shift 2 ;;
    --description-template)   DESCRIPTION_TEMPLATE="$2"; shift 2 ;;
    --cron-expr)              CRON_EXPR="$2"; shift 2 ;;
    --timezone)               TIMEZONE="$2"; shift 2 ;;
    --assignee-id)            ASSIGNEE_ID="$2"; shift 2 ;;
    --assignee-type)          ASSIGNEE_TYPE="$2"; shift 2 ;;
    --priority)               PRIORITY="$2"; shift 2 ;;
    --labels)                 LABELS="$2"; shift 2 ;;
    --starts-at)              STARTS_AT="$2"; shift 2 ;;
    --ends-at)                ENDS_AT="$2"; shift 2 ;;
    --max-instances)          MAX_INSTANCES="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

: "${PROJECT_ID:?--project-id is required}"
: "${TITLE_TEMPLATE:?--title-template is required}"
: "${FREQUENCY:?--frequency is required}"

BODY=$(jq -n \
  --arg title_template "$TITLE_TEMPLATE" \
  --arg frequency "$FREQUENCY" \
  --arg description_template "$DESCRIPTION_TEMPLATE" \
  --arg cron_expr "$CRON_EXPR" \
  --arg timezone "$TIMEZONE" \
  --arg assignee_id "$ASSIGNEE_ID" \
  --arg assignee_type "$ASSIGNEE_TYPE" \
  --arg priority "$PRIORITY" \
  --arg labels "$LABELS" \
  --arg starts_at "$STARTS_AT" \
  --arg ends_at "$ENDS_AT" \
  --arg max_instances "$MAX_INSTANCES" \
  '{title_template: $title_template, frequency: $frequency, priority: $priority, timezone: $timezone} +
   (if $description_template != "" then {description_template: $description_template} else {} end) +
   (if $cron_expr != "" then {cron_expr: $cron_expr} else {} end) +
   (if $assignee_id != "" then {assignee_id: $assignee_id, assignee_type: $assignee_type} else {} end) +
   (if $labels != "" then {labels: ($labels | split(","))} else {} end) +
   (if $starts_at != "" then {starts_at: $starts_at} else {} end) +
   (if $ends_at != "" then {ends_at: $ends_at} else {} end) +
   (if $max_instances != "" then {max_instances: ($max_instances | tonumber)} else {} end)')

mesh_curl -X POST "${MESH_API_URL}/api/v1/projects/${PROJECT_ID}/recurring" \
  -H "X-Agent-Key: ${MESH_AGENT_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" | jq .
