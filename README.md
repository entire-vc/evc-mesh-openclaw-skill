# EVC Mesh OpenClaw Skill

OpenClaw skill for [EVC Mesh](https://github.com/entire-vc/evc-mesh) — a task management platform for coordinating humans and AI agents.

Teaches OpenClaw agents to manage tasks, track progress, share context via events and persistent memory, and coordinate with other agents through shared task state.

## Prerequisites

- Running EVC Mesh instance (self-hosted or managed)
- Agent registered in EVC Mesh with an API key (`agk_...`)
- `curl` and `jq` available in shell

## Installation

```bash
# Copy to OpenClaw skills directory
cp -r . ~/.openclaw/skills/evc-mesh/
chmod +x ~/.openclaw/skills/evc-mesh/scripts/*.sh
```

Add to `~/.openclaw/openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "evc-mesh": {
        "env": {
          "MESH_API_URL": "https://your-mesh-instance.example.com",
          "MESH_AGENT_KEY": "agk_your_workspace_key"
        }
      }
    }
  }
}
```

## Quick Start

```bash
export MESH_API_URL="https://your-mesh-instance.example.com"
export MESH_AGENT_KEY="agk_your_workspace_key"

# Get your agent profile
bash scripts/whoami.sh

# Send heartbeat
bash scripts/heartbeat.sh online

# Auto-discover workspace, projects, statuses
bash scripts/discover.sh

# List my assigned tasks
bash scripts/my-tasks.sh

# Get enriched task context (task + comments + deps + artifacts)
bash scripts/get-context.sh <task_id>

# Move task to a different status
bash scripts/move-task.sh <task_id> <status_id>

# Add a comment
bash scripts/add-comment.sh <task_id> "Starting implementation"
```

## Agent Context Protocol (ACP)

At the beginning of **every** session, follow these steps:

```bash
# 1. Identity
bash scripts/whoami.sh

# 2. Discover environment
bash scripts/discover.sh --export

# 3. Load project knowledge (decisions, conventions)
bash scripts/get-project-knowledge.sh <project_id>

# 4. Understand constraints
bash scripts/get-workflow-rules.sh <project_id>

# 5. Heartbeat
bash scripts/heartbeat.sh online

# 6. Check assigned tasks
bash scripts/my-tasks.sh
```

At session end:
```bash
# Publish summary
bash scripts/publish-event.sh <project_id> summary "Session summary" '{"summary": "..."}'

# Remember decisions
bash scripts/remember.sh "decision-name" "What was decided" --scope project --tags decision

# Heartbeat
bash scripts/heartbeat.sh online
```

## Scripts (49)

### Identity & Discovery

| Script | Purpose | Args |
|--------|---------|------|
| `whoami.sh` | Get agent profile (id, workspace_id) | — |
| `heartbeat.sh` | Send heartbeat | `<status>` (online/busy/error) |
| `discover.sh` | Auto-discover workspace, projects, statuses | `[--export] [--json]` |
| `my-tasks.sh` | List tasks assigned to me | — |

### Projects

| Script | Purpose | Args |
|--------|---------|------|
| `list-projects.sh` | List workspace projects | `[workspace_id]` |
| `get-project.sh` | Get project details | `<project_id>` |
| `list-statuses.sh` | List project statuses | `<project_id>` |
| `list-custom-fields.sh` | List custom field definitions | `<project_id>` |

### Tasks

| Script | Purpose | Args |
|--------|---------|------|
| `list-tasks.sh` | List tasks (with filters) | `<project_id> [--status <id>] [--assignee me] [--priority <p>]` |
| `get-task.sh` | Get task details | `<task_id>` |
| `get-context.sh` | Get enriched task context | `<task_id>` |
| `create-task.sh` | Create a task | `<project_id> <title> [--priority p] [--description d] ...` |
| `update-task.sh` | Update task fields | `<task_id> [--title t] [--priority p] ...` |
| `move-task.sh` | Change task status | `<task_id> <status_id>` |
| `assign-task.sh` | Assign/unassign task | `<task_id> <agent_id> \| --unassign` |
| `delete-task.sh` | Delete a task | `<task_id>` |
| `create-subtask.sh` | Create subtask | `<parent_task_id> <title> [--priority p] ...` |
| `list-dependencies.sh` | List task dependencies | `<task_id>` |

### Atomic Task Checkout

| Script | Purpose | Args |
|--------|---------|------|
| `checkout-task.sh` | Lock task exclusively | `<task_id>` |
| `extend-checkout.sh` | Extend lock TTL | `<task_id>` |
| `release-task.sh` | Release lock | `<task_id>` |

### Comments & Artifacts

| Script | Purpose | Args |
|--------|---------|------|
| `add-comment.sh` | Add comment to task | `<task_id> <content>` |
| `list-comments.sh` | List task comments | `<task_id>` |
| `upload-artifact.sh` | Upload artifact | `<task_id> <name> <type> <file_or_content>` |
| `list-artifacts.sh` | List task artifacts | `<task_id>` |
| `download-artifact.sh` | Download artifact content | `<artifact_id> [--output <file>]` |

### VCS Links

| Script | Purpose | Args |
|--------|---------|------|
| `link-vcs.sh` | Link PR/commit/branch | `<task_id> <type> <external_id> <url> [--title t]` |
| `list-vcs-links.sh` | List VCS links on task | `<task_id>` |

### Event Bus

| Script | Purpose | Args |
|--------|---------|------|
| `publish-event.sh` | Publish event to bus | `<project_id> <event_type> <subject> <payload_json>` |
| `list-events.sh` | List project events | `<project_id>` |
| `get-activity.sh` | Get task activity log | `<task_id>` |

### Memory

| Script | Purpose | Args |
|--------|---------|------|
| `remember.sh` | Save knowledge (UPSERT by key) | `<key> <content> [--scope s] [--project-id id] [--tags t1,t2]` |
| `recall.sh` | Search memory (full-text) | `<query> [--scope s] [--project-id id] [--limit n]` |
| `get-project-knowledge.sh` | Get all project knowledge | `<project_id>` |
| `forget.sh` | Delete a memory entry | `<memory_id>` |

### Team & Governance

| Script | Purpose | Args |
|--------|---------|------|
| `list-agents.sh` | List agents in workspace | `[workspace_id]` |
| `get-team.sh` | Get team directory (agents + humans) | `[workspace_id]` |
| `get-workflow-rules.sh` | Get workflow rules for project | `<project_id>` |
| `get-assignment-rules.sh` | Get assignment rules for project | `<project_id>` |
| `update-agent-profile.sh` | Update agent profile fields | `[--role r] [--capabilities go,react] ...` |
| `set-callback-url.sh` | Set webhook callback URL | `<url>` |

### Config Management

| Script | Purpose | Args |
|--------|---------|------|
| `import-config.sh` | Import workspace config from YAML | `<path-to-yaml-file> [workspace_id]` |
| `export-config.sh` | Export workspace config as YAML | `[workspace_id] [--output file.yaml]` |

### Project Updates

| Script | Purpose | Args |
|--------|---------|------|
| `post-update.sh` | Post project status update | `<project_id> <title> <summary> [--status s]` |
| `list-triage.sh` | List triage inbox tasks | `<workspace_id>` |

### Recurring Tasks

| Script | Purpose | Args |
|--------|---------|------|
| `create-recurring-schedule.sh` | Create recurring schedule | `--project-id <id> --title-template <t> --frequency daily\|weekly\|monthly\|custom ...` |
| `list-recurring-schedules.sh` | List recurring schedules | `--project-id <id> [--active-only]` |
| `get-recurring-history.sh` | Get schedule instance history | `--schedule-id <id> [--limit n]` |
| `trigger-recurring-now.sh` | Trigger schedule immediately | `--schedule-id <id>` |

### Task Polling

| Script | Purpose | Args |
|--------|---------|------|
| `poll-tasks.sh` | Long-poll for new assignments | `[--timeout n]` |

## API Reference

See [references/api.md](references/api.md) for the complete REST API specification.

## Related

- [evc-mesh](https://github.com/entire-vc/evc-mesh) — Core platform (API + Web UI)
- [evc-mesh-mcp](https://github.com/entire-vc/evc-mesh-mcp) — MCP server (for Claude Code, Cursor, etc.)

## License

[MIT](LICENSE)
