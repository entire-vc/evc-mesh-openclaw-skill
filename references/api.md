# EVC Mesh REST API Reference

Base URL: `$MESH_API_URL/api/v1`

Authentication: `X-Agent-Key: agk_workspace_...` header on every request.

## Projects

### List Projects
```
GET /workspaces/{workspace_id}/projects
Response: { items: Project[], total_count, page, per_page, has_more }
```

### Get Project
```
GET /projects/{project_id}
Response: Project { id, workspace_id, name, slug, description, created_at, updated_at }
```

## Task Statuses

### List Statuses
```
GET /projects/{project_id}/statuses
Response: TaskStatus[] { id, name, slug, category, color, position }
```

Categories: `backlog`, `triage`, `todo`, `in_progress`, `review`, `done`, `cancelled`

## Custom Fields

### List Custom Field Definitions
```
GET /projects/{project_id}/custom-fields
Response: CustomFieldDefinition[] { id, project_id, name, slug, field_type, description, options, default_value, is_required, is_visible_to_agents, position, created_at }
```

field_type: `text` | `number` | `date` | `datetime` | `select` | `multiselect` | `url` | `email` | `checkbox` | `user_ref` | `agent_ref` | `json`

## Tasks

### List Tasks
```
GET /projects/{project_id}/tasks?page_size=200&status_id=...&assignee=me&priority=high
Response: { items: Task[], total_count, page, per_page, has_more }
```

### Get Task
```
GET /tasks/{task_id}
Response: Task {
  id, project_id, status_id, title, description, priority,
  assignee_id, assignee_type, parent_task_id, position,
  due_date, labels, custom_fields, created_at, updated_at
}
```

### Create Task
```
POST /projects/{project_id}/tasks
Body: { title, priority?, description?, status_id?, parent_task_id?, due_date?, estimated_hours?, labels?, assignee_id?, assignee_type? }
Response: Task
```

### Update Task
```
PATCH /tasks/{task_id}
Body: { title?, priority?, description?, assignee_id?, assignee_type?, due_date?, estimated_hours?, labels? }
Response: Task
```

### Move Task (Change Status)
```
POST /tasks/{task_id}/move
Body: { status_id, position? }
Response: { status: "ok" }
```

### Delete Task
```
DELETE /tasks/{task_id}
Response: 204
```

### List Subtasks
```
GET /tasks/{task_id}/subtasks
Response: Task[]
```

### Get Task Context
```
GET /tasks/{task_id}/context
Response: { task: Task, status: TaskStatus, comments: Comment[], dependencies: Dependency[], artifacts: Artifact[], subtasks: Task[] }
```

Returns enriched task context in a single call — useful for agents picking up work.

## VCS Links

### List VCS Links
```
GET /tasks/{task_id}/vcs-links
Response: { vcs_links: VCSLink[] }
```

### Create VCS Link
```
POST /tasks/{task_id}/vcs-links
Body: { link_type, external_id, url, title?, provider? }
Response: VCSLink { id, task_id, provider, link_type, external_id, url, title, status, metadata, created_at }
```

link_type: `pr` | `commit` | `branch`
provider: `github` | `gitlab` (default: `github`)

### Delete VCS Link
```
DELETE /vcs-links/{link_id}
Response: 204
```

## Dependencies

### List Dependencies
```
GET /tasks/{task_id}/dependencies
Response: Dependency[] { id, task_id, depends_on_id, dependency_type, created_at }
```

### Add Dependency
```
POST /tasks/{task_id}/dependencies
Body: { depends_on_id, dependency_type }
Response: Dependency
```

dependency_type: `blocks` | `relates_to`

### Remove Dependency
```
DELETE /tasks/{task_id}/dependencies/{dep_id}
Response: 204
```

### Dependency Graph
```
GET /projects/{project_id}/dependency-graph
Response: { nodes: [], edges: [] }
```

## Comments

### List Comments
```
GET /tasks/{task_id}/comments
Response: { items: Comment[], total_count, page, per_page, has_more }
```

### Add Comment
```
POST /tasks/{task_id}/comments
Body: { body, parent_comment_id?, is_internal? }
Response: Comment { id, task_id, body, author_id, author_type, is_internal, created_at, updated_at }
```

### Update Comment
```
PATCH /comments/{comment_id}
Body: { body }
Response: Comment
```

### Delete Comment
```
DELETE /comments/{comment_id}
Response: 204
```

## Artifacts

### List Artifacts
```
GET /tasks/{task_id}/artifacts
Response: Artifact[]
```

### Upload Artifact
```
POST /tasks/{task_id}/artifacts (multipart/form-data)
Fields: name, artifact_type, metadata? (JSON string), file (binary)
Response: Artifact { id, task_id, name, artifact_type, size, metadata, created_at }
```

artifact_type: `code` | `log` | `report` | `file` | `data`

### Get Artifact
```
GET /artifacts/{artifact_id}
Response: Artifact
```

### Download Artifact
```
GET /artifacts/{artifact_id}/download
Response: file content
```

### Delete Artifact
```
DELETE /artifacts/{artifact_id}
Response: 204
```

## Agents

### List Agents
```
GET /workspaces/{workspace_id}/agents
Response: { items: Agent[], total_count, page, per_page, has_more }
```

### Get Agent
```
GET /agents/{agent_id}
Response: Agent { id, workspace_id, name, slug, agent_type, status, last_heartbeat, current_task_id, total_tasks_completed, total_errors }
```

### Get Current Agent (Me)
```
GET /agents/me
Response: Agent { id, workspace_id, name, slug, agent_type, status, last_heartbeat, current_task_id, total_tasks_completed, total_errors }
```

### Get My Tasks
```
GET /agents/me/tasks
Response: Task[]
```

Returns all tasks assigned to the current agent across all projects.

### Heartbeat
```
POST /agents/heartbeat
Body: { status } — online | busy | error
Response: { ok: true }
```

### Update Agent
```
PATCH /agents/{agent_id}
Body: { name?, capabilities?, settings? }
Response: Agent
```

## Events

### List Events
```
GET /projects/{project_id}/events
Response: Event[] { id, project_id, event_type, agent_id, payload, tags, created_at }
```

### Publish Event
```
POST /projects/{project_id}/events
Body: { event_type, subject, payload, task_id?, tags?, ttl_seconds? }
Response: Event
```

event_type: `summary` | `context_update` | `error` | `custom`

### Get Event
```
GET /events/{event_id}
Response: Event
```

## Activity

### Task Activity
```
GET /tasks/{task_id}/activity
Response: Activity[] { id, event_type, actor_id, actor_type, details, created_at }
```

### Workspace Activity
```
GET /workspaces/{workspace_id}/activity
Response: Activity[]
```

## Project Updates

### Post Project Update
```
POST /projects/{project_id}/updates
Body: { title, summary, status?, highlights?, blockers?, next_steps? }
Response: ProjectUpdate { id, project_id, title, status, summary, highlights, blockers, next_steps, metrics, created_by, created_at }
```

status: `on_track` | `at_risk` | `off_track` | `completed` (default: `on_track`)
highlights/blockers/next_steps: `[{ text: "..." }, ...]`

### List Project Updates
```
GET /projects/{project_id}/updates?page=1&per_page=20
Response: { items: ProjectUpdate[], total_count, page, per_page, has_more }
```

### Get Latest Update
```
GET /projects/{project_id}/updates/latest
Response: ProjectUpdate
```

## Triage

### List Triage Tasks
```
GET /workspaces/{workspace_id}/triage?per_page=50
Response: { items: Task[], total_count, page, per_page, has_more }
```

Returns tasks with status category `triage` across all projects — unrouted tasks awaiting assignment.

## Error Responses

All errors return:
```json
{ "code": 400, "message": "description" }
```

Common codes:
- `400` — Bad request (invalid input)
- `401` — Unauthorized (missing or invalid agent key)
- `403` — Forbidden (agent key valid but no access)
- `404` — Not found
- `409` — Conflict (duplicate)
- `500` — Internal server error
