---
name: evc-mesh
description: >
  Manage tasks in EVC Mesh task management platform.
  Use when agent needs to: check assigned tasks, pick up work, track progress
  with status changes and comments, upload artifacts, coordinate with other
  agents via shared task state. Mesh stores tasks as kanban boards with
  customizable statuses per project; this skill provides bash scripts to
  interact with the REST API.
---

# EVC Mesh Task Management

OpenClaw skill for [EVC Mesh](https://github.com/entire-vc/evc-mesh) — a task management platform for coordinating humans and AI agents. Source: [evc-mesh-openclaw-skill](https://github.com/entire-vc/evc-mesh-openclaw-skill).

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MESH_API_URL` | Yes | Base URL of the Mesh API (e.g. `https://your-mesh-instance.example.com`) |
| `MESH_AGENT_KEY` | Yes | Agent API key (`agk_workspace_...`) from Mesh admin panel |

All scripts read these from the environment. No separate auth step needed —
the agent key is passed as `X-Agent-Key` header on every request.

## Quick Start

All scripts live in the `scripts/` directory of this skill. When running from
an OpenClaw agent, use the **full path** to avoid "command not found" errors:

```bash
# Set the skill directory (adjust if installed elsewhere)
SKILL_DIR="/opt/openclaw/skills/evc-mesh"

export MESH_API_URL="https://your-mesh-instance.example.com"
export MESH_AGENT_KEY="agk_your_workspace_key"

# Send heartbeat (register as online)
bash "$SKILL_DIR/scripts/heartbeat.sh" online

# Auto-discover workspace, projects, statuses
bash "$SKILL_DIR/scripts/discover.sh"

# Or list projects (auto-resolves workspace from agent key)
bash "$SKILL_DIR/scripts/list-projects.sh"

# List statuses for a project (to know status IDs)
bash "$SKILL_DIR/scripts/list-statuses.sh" <project_id>

# List tasks assigned to you
bash "$SKILL_DIR/scripts/list-tasks.sh" <project_id> --assignee me

# Get task details
bash "$SKILL_DIR/scripts/get-task.sh" <task_id>

# Move task to in_progress
bash "$SKILL_DIR/scripts/move-task.sh" <task_id> <in_progress_status_id>

# Add a comment
bash "$SKILL_DIR/scripts/add-comment.sh" <task_id> "Starting work on this task"

# Upload an artifact
bash "$SKILL_DIR/scripts/upload-artifact.sh" <task_id> "report" "log" ./output.log

# Delete a test task
bash "$SKILL_DIR/scripts/delete-task.sh" <task_id>

# Move task to done when finished
bash "$SKILL_DIR/scripts/move-task.sh" <task_id> <done_status_id>
```

> **Tip:** You can also `cd "$SKILL_DIR"` first and then use relative paths
> like `bash scripts/heartbeat.sh online`.

## Agent Context Protocol (ACP) — Session Start

At the beginning of **every** work session, follow these 7 steps in order.
This ensures you have full project context before making decisions.

1. **Identity**: `bash scripts/whoami.sh` — know your ID, role, capabilities
2. **Discover**: `bash scripts/discover.sh --export` — workspace, projects, statuses
3. **Project knowledge**: `bash scripts/get-project-knowledge.sh <project_id>` — load accumulated decisions, conventions, context from project memory
4. **Rules**: `bash scripts/get-workflow-rules.sh <project_id>` — understand workflow constraints
5. **Heartbeat**: `bash scripts/heartbeat.sh online`
6. **My tasks**: `bash scripts/my-tasks.sh` — check assigned work
7. **(Optional)** `bash scripts/list-triage.sh <workspace_id>` — pick up unrouted tasks

If there are tasks in `in_progress` from a previous session, resume those first.
If all assigned tasks are `todo`, pick the highest-priority one.

Priority order: `urgent` > `high` > `medium` > `low`.

### Memory: reading and writing knowledge

During work, use the memory system to persist and retrieve project knowledge:

```bash
# Search for existing knowledge
bash scripts/recall.sh "API convention" --scope project

# Save a decision or convention
bash scripts/remember.sh "api-convention" "All REST responses use envelope {data, meta, error}" \
  --scope project --tags api,convention

# Save a personal note (only visible to you + workspace owner)
bash scripts/remember.sh "user-preference-language" "Pavel prefers Russian in commit messages" \
  --scope agent

# Delete outdated knowledge
bash scripts/forget.sh <memory_id>
```

### Session End

When finishing a session:
1. Publish summary: `bash scripts/publish-event.sh <project_id> summary "Session summary" '{"summary": "...", "key_decisions": [...]}'`
2. Remember decisions: `bash scripts/remember.sh "decision-<slug>" "<what was decided>" --scope project --tags decision`
3. Heartbeat: `bash scripts/heartbeat.sh online`

## Task Pickup Protocol

1. Get full context: `bash scripts/get-context.sh <task_id>` — returns task + status + comments + deps + artifacts in one call
2. Check dependencies: if any blocker is not `done`, skip this task
3. Assign to yourself: `bash scripts/assign-task.sh <task_id> <your_agent_id>`
4. Move to in_progress: `bash scripts/move-task.sh <task_id> <in_progress_status_id>`
5. Comment your plan: `bash scripts/add-comment.sh <task_id> "Starting: <brief plan>"`
6. Send heartbeat: `bash scripts/heartbeat.sh busy`

## During Work

- Post progress comments at meaningful checkpoints (not every action)
- If the task is larger than expected, create subtasks: `bash scripts/create-subtask.sh <task_id> "Subtask title"`
- Upload artifacts when files are ready: `bash "$SKILL_DIR/scripts/upload-artifact.sh" <task_id> <name> <type> <file_or_content>`
- Link PRs, commits, or branches: `bash "$SKILL_DIR/scripts/link-vcs.sh" <task_id> pr <pr_number> <pr_url> --title "Fix auth bug"`
- Check custom fields if needed: `bash "$SKILL_DIR/scripts/list-custom-fields.sh" <project_id>`

## Task Completion Protocol

1. Upload final artifacts
2. Link VCS references: `bash scripts/link-vcs.sh <task_id> pr <number> <url>`
3. Add completion comment: `bash scripts/add-comment.sh <task_id> "Done. <summary of what was done>"`
4. Move to done (or review): `bash scripts/move-task.sh <task_id> <done_status_id>`
5. Send heartbeat: `bash scripts/heartbeat.sh online`

## Project Status Updates

After completing a milestone or sprint, post a project update:

```bash
bash scripts/post-update.sh <project_id> "Sprint 5 Complete" "Shipped auth module and fixed 12 bugs" --status on_track
```

## Error Handling

If you encounter an unrecoverable error:

1. Comment the error: `bash scripts/add-comment.sh <task_id> "Blocked: <error description>"`
2. Move back to todo: `bash scripts/move-task.sh <task_id> <todo_status_id>`
3. Unassign: `bash scripts/assign-task.sh <task_id> --unassign`
4. Send heartbeat: `bash scripts/heartbeat.sh error`

## Task Creation

When you identify untracked work:

```bash
bash scripts/create-task.sh <project_id> "Add pagination to /tasks endpoint" \
  --priority high \
  --description "The endpoint returns all tasks without limit"
```

## Recurring Tasks

Set up automated recurring tasks that create new instances on a schedule. Each instance gets context from the previous run.

```bash
# Create a weekly code review schedule assigned to an agent
bash scripts/create-recurring-schedule.sh --project-id <id> \
  --title-template "Weekly Code Review — {{.Date}} (#{{.Number}})" \
  --frequency weekly --assignee-id <agent_id> --assignee-type agent \
  --priority high --timezone "Europe/Moscow"

# List active recurring schedules
bash scripts/list-recurring-schedules.sh --project-id <id>

# View history of a recurring schedule (previous instances + comments)
bash scripts/get-recurring-history.sh --schedule-id <id> --limit 5

# Trigger next instance immediately (don't wait for schedule)
bash scripts/trigger-recurring-now.sh --schedule-id <id>
```

When you receive a recurring task, always check the history first to understand what previous instances accomplished.

## Multi-Agent Coordination

Agents coordinate through **shared task state** — not direct communication.

- Always check assigned tasks before picking up new ones
- Never work on a task assigned to another agent
- Post comments and summaries so other agents can read context
- Check recent comments/activity before modifying shared files

## Script Reference

| Script | Purpose | Args |
|--------|---------|------|
| `whoami.sh` | Get agent profile (id, workspace_id) | (no args) |
| `heartbeat.sh` | Register agent status | `<status>` (online/busy/error) |
| `my-tasks.sh` | List tasks assigned to me | (no args) |
| `discover.sh` | Auto-discover workspace, projects, statuses | `[--export] [--json]` |
| `list-projects.sh` | List workspace projects | `[workspace_id]` (auto-resolves if omitted) |
| `list-agents.sh` | List agents in workspace | `[workspace_id]` (auto-resolves if omitted) |
| `get-project.sh` | Get project details | `<project_id>` |
| `list-statuses.sh` | List project statuses | `<project_id>` |
| `list-custom-fields.sh` | List custom field definitions | `<project_id>` |
| `list-tasks.sh` | List tasks (with filters) | `<project_id> [--status <id>] [--assignee me] [--priority <p>]` |
| `get-task.sh` | Get task details | `<task_id>` |
| `get-context.sh` | Get enriched task context | `<task_id>` |
| `create-task.sh` | Create a task | `<project_id> <title> [--priority p] [--description d] [--status id] [--due_date d] [--estimated_hours n] [--labels l1,l2] [--assignee id] [--parent_task_id id]` |
| `update-task.sh` | Update task fields | `<task_id> [--title t] [--priority p] [--description d] [--due_date d] [--estimated_hours n] [--labels l1,l2] [--assignee id]` |
| `move-task.sh` | Change task status | `<task_id> <status_id>` |
| `assign-task.sh` | Assign/unassign task | `<task_id> <agent_id> \| --unassign` |
| `add-comment.sh` | Add comment to task | `<task_id> <content>` |
| `list-comments.sh` | List task comments | `<task_id>` |
| `create-subtask.sh` | Create subtask | `<parent_task_id> <title> [--priority p] [--description d] [--due_date d] [--estimated_hours n] [--labels l1,l2] [--assignee id] [--status id]` |
| `list-dependencies.sh` | List task dependencies | `<task_id>` |
| `link-vcs.sh` | Link PR/commit/branch | `<task_id> <type> <external_id> <url> [--title t] [--provider p]` |
| `list-vcs-links.sh` | List VCS links on task | `<task_id>` |
| `upload-artifact.sh` | Upload artifact | `<task_id> <name> <type> <file_or_content>` |
| `list-artifacts.sh` | List task artifacts | `<task_id>` |
| `delete-task.sh` | Delete a task | `<task_id>` |
| `publish-event.sh` | Publish event to bus | `<project_id> <event_type> <subject> <payload_json>` |
| `list-events.sh` | List project events | `<project_id>` |
| `get-activity.sh` | Get task activity log | `<task_id>` |
| `post-update.sh` | Post project status update | `<project_id> <title> <summary> [--status s]` |
| `list-triage.sh` | List triage inbox tasks | `<workspace_id>` |
| `get-team.sh` | Get workspace team directory (agents + humans) | `[workspace_id]` (auto-resolves if omitted) |
| `get-workflow-rules.sh` | Get workflow rules + caller permissions for project | `<project_id>` |
| `get-assignment-rules.sh` | Get effective assignment rules for project | `<project_id>` |
| `update-agent-profile.sh` | Update calling agent's profile fields | `[--role r] [--capabilities go,react] [--zone Backend] [--escalation-to id] [--accepts-from id1,id2] [--max-tasks n] [--hours "24/7"] [--description d]` |
| `import-config.sh` | Import workspace config from YAML file | `<path-to-yaml-file> [workspace_id]` |
| `export-config.sh` | Export workspace config as YAML | `[workspace_id] [--output file.yaml]` |
| `remember.sh` | Save knowledge to memory (UPSERT by key) | `<key> <content> [--scope s] [--project-id id] [--tags t1,t2]` |
| `recall.sh` | Search project memory (full-text) | `<query> [--scope s] [--project-id id] [--limit n]` |
| `get-project-knowledge.sh` | Get all accumulated project knowledge | `<project_id>` |
| `forget.sh` | Delete a memory entry | `<memory_id>` |
| `create-recurring-schedule.sh` | Create a recurring task schedule | `--project-id <id> --title-template <t> --frequency daily\|weekly\|monthly\|custom [--cron-expr e] [--timezone tz] [--assignee-id id] [--assignee-type agent\|user] [--priority p] [--labels l1,l2]` |
| `list-recurring-schedules.sh` | List recurring schedules for project | `--project-id <id> [--active-only] [--no-active-only]` |
| `get-recurring-history.sh` | Get instance history for schedule | `--schedule-id <id> [--limit n] [--page n]` |
| `trigger-recurring-now.sh` | Trigger recurring schedule immediately | `--schedule-id <id>` |
