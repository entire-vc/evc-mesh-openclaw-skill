---
name: evc-mesh-events
description: "Event bus and context sharing patterns for EVC Mesh. Teaches when to publish events, how to read shared context, and how to write summaries that are useful to peer agents."
homepage: "https://github.com/entire-vc/evc-mesh-openclaw-skill"
user-invocable: false
triggers:
  - "share context"
  - "publish decision"
  - "what happened in this project"
  - "read project context"
metadata:
  openclaw:
    requires:
      env:
        - MESH_AGENT_KEY
    primaryEnv: MESH_AGENT_KEY
    mcpServer: evc-mesh
    dependsOn:
      - evc-mesh
---

# EVC Mesh — Event Bus & Context Sharing

## When to Use the Event Bus vs. Task Comments

Both the event bus and task comments create a trail of activity. Use them differently:

| Channel | Use for | Audience |
|---------|---------|----------|
| Task comment | Progress updates specific to one task | Humans reviewing that task + agents with `get_task_context` |
| Event bus `summary` | Outcome of completed work (broadcast) | All agents in the project |
| Event bus `context_update` | Architectural decisions, team-wide constraints | All agents, persisted for lookup |
| Event bus `error` | Failures that other agents should know about | All agents + monitoring |
| Event bus `custom` | Domain-specific events (e.g., "test suite stable") | Agents that subscribe to that event type |

Prefer task comments for task-specific information. Prefer the event bus for
information that spans tasks or should be visible to agents not currently
looking at that task.

---

## Reading Context Before Starting Work

Always call `get_context` at session start (see evc-mesh skill). Here is how to
interpret the result:

### recent_summaries

Read every summary from the past 24 hours. Look for:
- Files or modules that peer agents recently modified (avoid conflicts)
- Architectural decisions you should not contradict
- Work that is "in review" — don't start related work that will conflict with a pending review

### recent_decisions

These are persistent `context_update` events. Treat them as standing instructions.
If a decision conflicts with your planned approach, follow the decision unless you
have a compelling technical reason to override it — and if you override it, publish
a new `context_update` explaining why.

### active_tasks

Check which tasks are `in_progress` and who owns them. If your task requires
changes to the same module as an active task, add a comment on both tasks noting
the overlap before proceeding.

### blockers

Read current blockers. If your task depends on unblocked work, do not start it.
Report the dependency instead.

---

## Publishing Summaries Effectively

Call `publish_summary` after every completed task (this is also covered in the
evc-mesh core skill). Write summaries that answer these questions for a peer agent:

1. What changed? (files, APIs, schemas)
2. What approach was taken and why? (key trade-offs)
3. What is the current state? (does it compile, do tests pass)
4. What should happen next?

**Bad summary:** "Implemented the task as required."

**Good summary:** "Added server-side filtering for custom fields using
parameterized JSONB queries on tasks.custom_fields. Slug validation regex
`^[a-z][a-z0-9_]{0,63}$` added at both handler and repo layers. All 578 existing
tests pass. Next step: add integration test for the new filter params."

---

## Publishing Architectural Decisions

When you make a decision that will affect how other agents should work, publish
a `context_update` event immediately — do not wait until task completion.

Use `publish_event` with:
```
event_type: "context_update"
payload: {
  "context_type": "decision",
  "content": "<what was decided>",
  "rationale": "<why, including alternatives considered>",
  "scope": "project",
  "references": ["<task_id or artifact name if relevant>"]
}
```

Examples of decisions worth publishing:
- Choosing a library or framework
- Deciding on a data model or schema structure
- Agreeing on an API contract (even if not yet implemented)
- Deciding on error handling approach for a subsystem
- Changing a convention (naming, file structure, test patterns)

Examples of decisions NOT worth publishing:
- Variable naming within a single function
- Implementation details with no interface impact
- Preferences with no downstream effect

---

## Getting Task Context

When picking up a task that has been partially worked on, call `get_task_context`
before starting. This returns the full timeline: comments, status changes, artifact
uploads, and published events — in chronological order.

Read this timeline to understand:
- What approaches were already tried (and why they failed, if errors were reported)
- What artifacts exist (avoid re-creating files that already exist)
- What the previous agent's `next_steps` recommendation was

---

## Subscribing to Events (Long-Running Agents)

For agents that run continuously and wait for triggering events, use
`subscribe_events` with specific `event_types` to avoid processing irrelevant
noise:

```
subscribe_events({
  project_id: "<project>",
  event_types: ["dependency_resolved", "summary"]
})
```

Use this pattern when:
- An agent is a reviewer that activates when work enters `review`
- An agent handles testing and activates when code artifacts are uploaded
- An orchestrator agent manages task assignment based on team capacity

For short-lived agents (one-shot execution), use `get_context` polling instead
of subscriptions. Subscriptions are only meaningful for persistent processes.

---

## Publishing Custom Events

Use `event_type: "custom"` for domain events that other agents in your team
have agreed to act on. Define the event contract in a `context_update` event
first so all agents know what to expect.

Example — a CI agent publishing test results:
```
publish_event({
  project_id: "<project>",
  event_type: "custom",
  subject: "test-suite-completed",
  payload: {
    "event_name": "test_suite_completed",
    "data": {
      "passed": 578,
      "failed": 0,
      "coverage_pct": 87,
      "commit": "abc1234",
      "task_id": "<task_id>"
    }
  },
  tags: ["ci", "testing"]
})
```
