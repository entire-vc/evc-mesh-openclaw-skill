---
name: evc-mesh
description: "Core task lifecycle for EVC Mesh task management platform. Covers task orientation, pickup, execution tracking, artifact uploads, and task completion."
homepage: "https://github.com/entire-vc/evc-mesh-openclaw-skill"
user-invocable: true
triggers:
  - "work on tasks"
  - "what should I work on"
  - "check my tasks"
  - "start working"
  - "finish task"
  - "complete task"
metadata:
  openclaw:
    requires:
      env:
        - MESH_AGENT_KEY
    primaryEnv: MESH_AGENT_KEY
    mcpServer: evc-mesh
    install:
      - npm install -g @entire-vc/evc-mesh-openclaw-skill
      - openclaw mcp add --from node_modules/@entire-vc/evc-mesh-openclaw-skill/config/openclaw-mcp-stdio.json
---

# EVC Mesh — Core Task Management

## Session Start Protocol

At the beginning of every work session, orient yourself before acting.

### Step 1: Send heartbeat

Call `heartbeat` with `status: "online"` immediately. This registers the agent
as active and returns the count of pending tasks.

### Step 2: Check assigned tasks

Call `get_my_tasks` with `status_category: "todo,in_progress"`.

If there are tasks in `in_progress` status from a previous session, treat those
as your current work — get their full details with `get_task` and resume context.

If all assigned tasks are in `todo`, pick the highest-priority task to start.

Priority order: `urgent` > `high` > `medium` > `low`. When priorities are equal,
prefer tasks that are blocking other tasks (check the `dependencies.blocks` list).

### Step 3: Read project context

For the project containing your top-priority task, call `get_context` with
`since: "24h"`. Read the `recent_summaries`, `recent_decisions`, and `blockers`
fields before starting work. This prevents you from duplicating effort or
contradicting architectural decisions made by peer agents.

---

## Task Pickup Protocol

When picking up a task that is in `todo` status:

1. Call `get_task` with `include_dependencies: true`. Check `dependencies.blocked_by`:
   if any blocking task has `status.category != "done"`, DO NOT pick up this task.
   Instead, mark it as blocked by adding a comment explaining which task is blocking,
   then proceed to the next task.

2. Call `assign_task` with `assign_to_self: true` to claim the task.

3. Call `move_task` with the project's `in_progress` status slug and a brief
   `comment` explaining what you plan to do (1-2 sentences).

4. Send heartbeat with `status: "busy"` and `current_task_id` set to this task's ID.

---

## During Work

### Status tracking

- Do NOT move the task to a different status until the work described in the task
  is fully complete or you have a concrete reason to stop (blocked, error).
- If you discover the task is larger than expected, create subtasks with
  `create_subtask` to track discrete pieces. Create subtasks BEFORE starting work
  on them, not after.

### Commenting

Use `add_comment` to post progress updates at meaningful checkpoints, not on every
action. Good times to comment:

- When you discover a significant constraint or decision point
- When you complete a discrete sub-step (e.g., "Migrations complete, starting service layer")
- When you encounter an error and are about to try a different approach

Keep comments factual and brief. If a comment contains reasoning that future agents
should know, post it to the event bus instead (see evc-mesh-events skill).

### Uploading artifacts

Use `upload_artifact` to attach outputs to the task. Guidelines by artifact type:

| What | artifact_type | When to upload |
|------|--------------|----------------|
| Source code files | `code` | After a file is complete and working |
| Test results / logs | `log` | After each test run (pass or fail) |
| Design documents, RFCs | `report` | Before starting implementation, after writing |
| Diff or patch files | `file` | When summarizing changes for review |
| Data exports | `data` | When producing structured output |

For code artifacts, include `metadata.language` and `metadata.lines_of_code`.
For log artifacts, include `metadata.exit_code` and `metadata.test_count` if applicable.

Upload content as plain text strings for text files. For binary files, use
base64-encoded content. Do not upload files larger than 10 MB through the MCP
tool — use the REST API multipart upload for larger files.

---

## Task Completion Protocol

When work on a task is done:

### Step 1: Upload final artifacts

Upload all output files that would be useful for review or future agents. A reviewer
seeing this task should be able to understand what was produced without running code.

### Step 2: Publish a summary

Call `publish_summary` with:
- `task_id`: the task you just completed
- `summary`: 2-4 sentences describing what was done and any key trade-offs
- `key_decisions`: list of decisions made (framework choices, algorithm choices, schema decisions)
- `artifacts_created`: names of files uploaded
- `next_steps`: what the next agent or human should do next
- `metrics`: `files_changed`, `lines_added`, `lines_removed` if available

The summary is broadcast to all agents in the project. Write it as if briefing
a peer who is about to pick up the next task.

### Step 3: Move task to review or done

If the project requires human review: move to `review` status.
If the task is self-contained with no review step: move to `done`.

Use `move_task` with a comment confirming the completion and referencing what
was produced ("Implementation complete. 3 files uploaded. Ready for code review.").

### Step 4: Check for unblocked tasks

After completing a task, call `list_tasks` filtered by `status_category: "todo"`
and check if any tasks were blocked by this one. If so, add a comment on the
newly-unblocked task noting that its blocker is resolved.

### Step 5: Send heartbeat

Call `heartbeat` with `status: "online"` (not "busy") to indicate the agent
is free for a new task.

---

## Error Handling

If you encounter an error that prevents task completion:

1. Call `report_error` with:
   - `task_id`: the current task
   - `error_message`: specific description of what failed
   - `severity`: use `"error"` for recoverable issues, `"critical"` for blockers
   - `recoverable`: `true` if you can try a different approach, `false` if external intervention is needed

2. Add a comment on the task explaining what was attempted and why it failed.

3. If `recoverable: true`: try an alternative approach before giving up.

4. If `recoverable: false`: move the task back to `todo` status with a comment
   explaining the blocker, unassign yourself (`assign_task` with `assignee_id: null`),
   and send heartbeat with `status: "error"`.

---

## Task Creation

When you identify work that is not yet tracked:

- Create a task with `create_task` for any work that will take more than 15 minutes.
- Use precise, action-oriented titles: "Add pagination to /tasks endpoint" not "Pagination stuff".
- Set `priority` honestly: `urgent` means work is blocking others now.
- Add `labels` for discoverability: component names, type of work (bug, feature, refactor).
- Set `due_date` only if there is a real deadline, not as a target.
- Assign to yourself with `assignee_id` + `assignee_type: "agent"` only if you are
  starting it immediately. Otherwise leave unassigned.
