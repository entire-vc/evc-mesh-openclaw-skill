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

## Session Start Protocol

At the beginning of every work session:

1. **Discover environment**: `bash scripts/discover.sh --export` — gets agent ID, workspace, projects, statuses in one call
2. **Send heartbeat**: `bash scripts/heartbeat.sh online`
3. **(Optional) List agents**: `bash scripts/list-agents.sh` — see other agents in workspace for coordination
5. **Check assigned tasks**: `bash scripts/my-tasks.sh` — shows all tasks assigned to you
6. **Read context**: Check recent comments and activity on your tasks
7. **Check triage inbox**: `bash scripts/list-triage.sh <workspace_id>` — pick up unrouted tasks

If there are tasks in `in_progress` from a previous session, resume those first.
If all assigned tasks are `todo`, pick the highest-priority one.

Priority order: `urgent` > `high` > `medium` > `low`.

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
