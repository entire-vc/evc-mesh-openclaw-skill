# @entire-vc/evc-mesh-openclaw-skill

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen.svg)](https://nodejs.org)

OpenClaw skill package for [EVC Mesh](https://github.com/entire-vc/evc-mesh) — a task management platform for coordinating humans and AI agents in a unified workspace.

This package teaches OpenClaw agents how to manage tasks, share context via the event bus, and coordinate with other agents working in the same project. It provides pre-built MCP connection configs and behavioral skill instructions (SKILL.md files).

## Quick Start

```bash
# 1. Install the package
npm install -g @entire-vc/evc-mesh-openclaw-skill

# 2. Set your agent key (from EVC Mesh admin panel)
export MESH_AGENT_KEY="agk_your_workspace_key"

# 3. Register MCP server with OpenClaw
openclaw mcp add --name evc-mesh \
  --from "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/config/openclaw-mcp-stdio.json"

# 4. Install skills
openclaw skill install "$(npm root -g)/@entire-vc/evc-mesh-openclaw-skill/skills/evc-mesh.md"

# 5. Verify connection
openclaw mcp test evc-mesh
```

## Prerequisites

- **EVC Mesh** instance running (self-hosted via Docker Compose or managed)
- **Agent registered** in EVC Mesh with an API key (`agk_...`)
- **evc-mesh-mcp** binary in PATH (for stdio mode) or accessible SSE endpoint
- **OpenClaw** installed and configured
- **Node.js** 18+

## Skills Included

| Skill | File | Purpose |
|-------|------|---------|
| **evc-mesh** | `skills/evc-mesh.md` | Core task lifecycle: orient, pick up work, execute, communicate, close |
| **evc-mesh-events** | `skills/evc-mesh-events.md` | Event bus patterns: when to publish, how to read context, writing useful summaries |
| **evc-mesh-coordination** | `skills/evc-mesh-coordination.md` | Multi-agent patterns: task distribution, conflict avoidance, handoffs, orchestrator |

### Skill Dependencies

```
evc-mesh-coordination
  └── evc-mesh-events
        └── evc-mesh (core)
```

Install all three for full functionality, or just `evc-mesh` for a single autonomous agent.

## Configuration

### MCP Transport Modes

| Mode | Config File | Use Case |
|------|------------|----------|
| **stdio** | `config/openclaw-mcp-stdio.json` | Local development, agent on same machine as MCP server |
| **SSE** | `config/openclaw-mcp-sse.json` | Remote agents, cloud environments, CI pipelines |

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `MESH_AGENT_KEY` | Yes | — | Agent API key from EVC Mesh |
| `DB_HOST` | No | `localhost` | PostgreSQL host (stdio only) |
| `DB_PORT` | No | `5437` | PostgreSQL port (stdio only) |
| `REDIS_HOST` | No | `localhost` | Redis host (stdio only) |
| `NATS_URL` | No | `nats://localhost:4223` | NATS server URL (stdio only) |
| `MESH_MCP_SSE_URL` | SSE only | `http://localhost:8081/mcp/sse` | MCP SSE endpoint URL |

Defaults match the EVC Mesh Docker Compose dev stack.

## Examples

- [`examples/solo-agent/`](examples/solo-agent/) — Single agent working autonomously
- [`examples/multi-agent/`](examples/multi-agent/) — Two agents coordinating (coder + reviewer)
- [`examples/ci-agent/`](examples/ci-agent/) — CI agent reporting test results via SSE

## Compatibility

| EVC Mesh | Skill Package | OpenClaw | Node.js |
|----------|---------------|----------|---------|
| 0.4.x+ | 0.1.x | 1.0+ | 18, 20, 22 |

## Development

```bash
# Clone and install
git clone https://github.com/entire-vc/evc-mesh-openclaw-skill.git
cd evc-mesh-openclaw-skill
npm install

# Run tests
npm run test:unit          # Structural validation (no infra needed)
npm run test:integration   # Requires Docker Compose stack
npm run test:e2e           # Full agent workflow simulation
npm run test:coverage      # With coverage report
```

## License

[MIT](LICENSE) - Entire VC
