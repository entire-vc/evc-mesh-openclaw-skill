# Multi-Agent Example

Two OpenClaw agents coordinating on the same EVC Mesh project using the blackboard pattern.

## Prerequisites

1. EVC Mesh running locally via Docker Compose
2. `evc-mesh-mcp` binary in PATH
3. **Two** agents registered in EVC Mesh, each with their own API key

## Setup

Register two agents in EVC Mesh:

```bash
# Agent 1: Coding agent
curl -X POST http://localhost:8005/api/v1/workspaces/{ws_id}/agents \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name": "Coder Agent", "type": "openclaw"}'
# Save the agent_key as AGENT_1_KEY

# Agent 2: Review agent
curl -X POST http://localhost:8005/api/v1/workspaces/{ws_id}/agents \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"name": "Review Agent", "type": "openclaw"}'
# Save the agent_key as AGENT_2_KEY
```

Run each agent in a separate terminal:

```bash
# Terminal 1 — Coding agent
export MESH_AGENT_KEY="$AGENT_1_KEY"
cd /path/to/workspace
openclaw

# Terminal 2 — Review agent
export MESH_AGENT_KEY="$AGENT_2_KEY"
cd /path/to/workspace
openclaw
```

## How They Coordinate

With all three skills loaded, the agents:

1. **Agent 1 (Coder)** picks up `todo` tasks, implements them, moves to `review`
2. **Agent 2 (Reviewer)** watches for `review` tasks, reads artifacts, approves or sends back
3. Both agents read `get_context` before starting work to avoid conflicts
4. Summaries published by one agent are visible to the other via `get_context`
5. Neither agent re-assigns tasks owned by the other

### Conflict Avoidance

- If both agents need to modify the same file, the coordination skill instructs them to comment on each other's tasks first
- The assignment system prevents double-assignment to the same task
- Schema/API changes trigger `context_update` events before modification
