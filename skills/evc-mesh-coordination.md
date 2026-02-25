---
name: evc-mesh-coordination
description: "Multi-agent coordination patterns for EVC Mesh. Covers task distribution, conflict avoidance, handoffs, and orchestrator patterns."
homepage: "https://github.com/entire-vc/evc-mesh-openclaw-skill"
user-invocable: true
triggers:
  - "coordinate agents"
  - "distribute work"
  - "multi-agent"
  - "handoff"
  - "assign to agent"
metadata:
  openclaw:
    requires:
      env:
        - MESH_AGENT_KEY
    primaryEnv: MESH_AGENT_KEY
    mcpServer: evc-mesh
    dependsOn:
      - evc-mesh
      - evc-mesh-events
---

# EVC Mesh — Multi-Agent Coordination

## Core Principle

Agents coordinate through **shared task state** and **event bus summaries**, not
through direct communication. An agent does not need to know which other agents
are running or their addresses. It needs to:

1. Claim tasks before starting (via `assign_task` + status move to `in_progress`)
2. Publish summaries when done
3. Check context before starting (to learn what peers have done)

This is the "blackboard pattern": the task board and event bus are the shared
blackboard. Agents read and write to it; they do not message each other directly.

---

## Conflict Avoidance

### File-level conflicts

Before modifying a file, check `get_context` for recent summaries mentioning
that file. If another agent has modified it in the past hour, either:
- Coordinate by commenting on their task: "I also need to modify X file, let's
  discuss approach before both editing it."
- Break your work into a separate task and add it as a dependency on their task.

### Task-level conflicts

Two agents should never be `in_progress` on the same task. The assignment system
prevents this, but if you discover a task assigned to another agent that you also
need to modify, do NOT re-assign it. Instead, create a subtask or a dependency.

### Schema/API conflicts

If your task requires changing a database schema or API contract, publish a
`context_update` with `context_type: "instruction"` BEFORE making the change,
with a description of what will change. Give other agents time to adapt.

---

## Orchestrator Pattern

An orchestrator agent is responsible for creating and assigning tasks rather than
implementing them. It should:

### At sprint start

1. Call `get_project` to load current statuses and custom fields.
2. Call `list_tasks` with `status_category: "backlog"` to see the backlog.
3. For each agent in the team, call `list_tasks` with their `assignee_id` to
   see their current load.
4. Assign backlog tasks to agents based on capacity and skill:
   - Use `assign_task` to assign tasks.
   - Move tasks from `backlog` to `todo` to signal they are ready.
   - Set dependencies with `add_dependency` for tasks that must be sequenced.

### Monitoring progress

1. Periodically call `get_context` with `since: "1h"` to see what has been done.
2. If a task has been `in_progress` for more than the expected duration without
   a summary or comment, add a comment asking for a status update.
3. If an error event appears (`event_type: "error"`, `severity: "critical"`),
   investigate: call `get_task_context` for the related task and decide whether
   to reassign or break the task into smaller pieces.

### At sprint end

1. Call `list_tasks` with `status_category: "done"` and count completions.
2. Move any incomplete `in_progress` tasks back to `todo` after unassigning them.
3. Publish a `summary` event with sprint outcomes using `publish_summary`.

---

## Specialist Agent Patterns

### Coding Agent

Focus: `todo` and `in_progress` tasks with implementation work.

Workflow:
1. `get_my_tasks` — find assigned `todo` tasks
2. Check blockers via `get_task` with `include_dependencies: true`
3. Pick up highest-priority unblocked task
4. Execute, upload artifacts (`artifact_type: "code"`)
5. `publish_summary` + move to `review`

### Review Agent

Focus: tasks in `review` status.

Workflow:
1. `list_tasks` with `status_category: "review"` — find tasks awaiting review
2. `get_task_context` — read full history: what was done, what artifacts exist
3. `get_artifact` with `include_content: true` for code artifacts
4. Evaluate and either:
   - Move to `done` with approval comment
   - Move back to `in_progress` with specific feedback comment
5. `publish_event` with `event_type: "context_update"` and `context_type: "information"`
   noting any patterns or issues found during review

### Test/CI Agent

Focus: triggered by code artifact uploads or `review` tasks.

Workflow:
1. Subscribe to `custom` events with tag `ci` or subscribe via `get_context` polling
2. When triggered, `get_task` to find the associated code artifacts
3. `get_artifact` with `include_content: true` to retrieve code
4. Run tests in the local environment
5. `upload_artifact` with `artifact_type: "log"` for test output
6. Publish `custom` event with test results (see evc-mesh-events skill)
7. If tests fail, add comment on task with specific failure details and move back
   to `in_progress`
8. If tests pass, move task forward or add approval comment

---

## Handoff Protocol

When an agent needs to hand work off mid-task (session limit, context switch,
or planned handoff to a specialist):

1. Upload all in-progress artifacts (even partial ones, use `name: "wip_filename.go"`)
2. Add a detailed comment on the task: current state, what has been done, what
   remains, specific next action
3. Call `publish_summary` with `next_steps` being very specific (not "continue
   the work" but "the function `handleCreateTask` in `api/handlers/task.go`
   needs error handling for the case where `project_id` does not exist")
4. Move task back to `todo` (NOT `backlog`)
5. Unassign yourself (or re-assign to the receiving agent if known)

The receiving agent should: `get_task_context` for the full history, `list_artifacts`
to see what exists, then proceed from the `next_steps` in the last summary.

---

## Dependency Management

Use task dependencies (`add_dependency`) to model real blocking relationships.
Do not use them as informal priority signals.

When to add a `blocks` dependency:
- Task A cannot start until Task B is done (e.g., "Write API tests" blocks on
  "Implement API endpoints")
- Task A and Task B modify the same interface (schema, API contract) and must be
  sequenced

When to add a `relates_to` dependency:
- Tasks are in the same feature area and a reviewer should see both together
- Tasks share context but are not strictly sequential

After completing a task, always check:
1. Does completing this task resolve blockers for other tasks?
2. Call `list_tasks` filtered for `todo` and look for tasks with this task in
   their `dependencies.blocked_by` list.
3. For each newly-unblocked task: add a comment noting it is now unblocked,
   and optionally publish a `dependency_resolved` event.
