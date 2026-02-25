# Solo Agent Example

A single OpenClaw agent working autonomously on tasks in an EVC Mesh project.

## Prerequisites

1. EVC Mesh running locally via Docker Compose (`docker compose up -d` in the evc-mesh repo)
2. `evc-mesh-mcp` binary in PATH (build with `go build -o /usr/local/bin/evc-mesh-mcp ./cmd/mcp` in evc-mesh repo)
3. An agent registered in EVC Mesh with an API key

## Setup

```bash
# Set your agent key
export MESH_AGENT_KEY="agk_your_workspace_key"

# Copy this openclaw.json to your workspace
cp openclaw.json /path/to/your/workspace/

# Start OpenClaw in the workspace
cd /path/to/your/workspace
openclaw
```

## What the Agent Will Do

With the `evc-mesh` skill loaded, the agent will:

1. Send a heartbeat to register as online
2. Check for assigned tasks (highest priority first)
3. Read project context from the last 24 hours
4. Pick up a task, move it to `in_progress`
5. Work on the task, posting progress comments
6. Upload artifacts (code, logs, reports)
7. Publish a summary and move the task to `done`
8. Check for newly-unblocked tasks and repeat

## Customization

- Change `DB_HOST`, `DB_PORT`, etc. if your EVC Mesh runs on a different host
- For SSE transport (remote MCP server), replace the `mcpServers` block with the SSE config from `config/openclaw-mcp-sse.json`
