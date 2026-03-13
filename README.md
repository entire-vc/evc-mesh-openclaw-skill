# EVC Mesh OpenClaw Skill

[![Install via Spark](https://spark.entire.vc/badges/evc-mesh-openclaw-skill/install.svg)](https://spark.entire.vc/assets/evc-mesh-openclaw-skill?utm_source=github&utm_medium=readme)

OpenClaw skill for [EVC Mesh](https://github.com/entire-vc/evc-mesh) — a task management platform for coordinating humans and AI agents.

Teaches OpenClaw agents to manage tasks, track progress, share context via comments and events, and coordinate with other agents through shared task state.

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

# Get your agent profile (ID, workspace_id)
bash scripts/whoami.sh

# Check agent status
bash scripts/heartbeat.sh online

# List projects
bash scripts/list-projects.sh <workspace_id>

# List my assigned tasks (across all projects)
bash scripts/my-tasks.sh

# List tasks in a project
bash scripts/list-tasks.sh <project_id>

# Get enriched task context (task + deps + comments + artifacts)
bash scripts/get-context.sh <task_id>

# Move task to a different status
bash scripts/move-task.sh <task_id> <status_id>

# Add a comment
bash scripts/add-comment.sh <task_id> "Starting implementation"
```

## Scripts

| Script | Purpose |
|--------|---------|
| `whoami.sh` | Get agent profile (ID, workspace_id, name) |
| `heartbeat.sh` | Send agent heartbeat (online/busy/error) |
| `list-projects.sh` | List workspace projects |
| `get-project.sh` | Get project details |
| `list-statuses.sh` | List project statuses (with IDs and categories) |
| `list-tasks.sh` | List tasks with optional filters |
| `get-task.sh` | Get task details |
| `create-task.sh` | Create a new task (all fields supported) |
| `update-task.sh` | Update task fields (all fields supported) |
| `move-task.sh` | Change task status |
| `assign-task.sh` | Assign or unassign a task |
| `add-comment.sh` | Add comment to task |
| `list-comments.sh` | List task comments |
| `create-subtask.sh` | Create subtask under parent |
| `list-dependencies.sh` | List task dependencies |
| `upload-artifact.sh` | Upload artifact to task |
| `list-artifacts.sh` | List task artifacts |
| `publish-event.sh` | Publish event to project bus |
| `list-events.sh` | List project events |
| `get-activity.sh` | Get task activity log |
| `my-tasks.sh` | List tasks assigned to current agent |
| `get-context.sh` | Get enriched task context (task + status + comments + deps + artifacts) |
| `list-custom-fields.sh` | List custom field definitions for a project |
| `link-vcs.sh` | Link PR, commit, or branch to a task |
| `list-vcs-links.sh` | List VCS links on a task |
| `post-update.sh` | Post project status update |
| `list-triage.sh` | List triage inbox tasks (unrouted, awaiting assignment) |

## API Reference

See [references/api.md](references/api.md) for the complete REST API specification.

## License

[MIT](LICENSE)
