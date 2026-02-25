# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-25

### Added

- **Core skill** (`skills/evc-mesh.md`): Task lifecycle management — session start protocol, task pickup, execution tracking with artifacts, completion protocol with summaries, error handling, task creation guidelines
- **Events skill** (`skills/evc-mesh-events.md`): Event bus patterns — when to use event bus vs task comments, reading context before work, publishing summaries effectively, architectural decisions, subscribing to events, custom events
- **Coordination skill** (`skills/evc-mesh-coordination.md`): Multi-agent patterns — conflict avoidance (file, task, schema level), orchestrator pattern, specialist agent workflows (coding, review, CI), handoff protocol, dependency management
- **MCP config** (`config/openclaw-mcp-stdio.json`): stdio transport config with env var defaults matching EVC Mesh Docker Compose dev stack
- **MCP config** (`config/openclaw-mcp-sse.json`): SSE transport config for remote MCP server connections
- **Docker Compose** (`config/docker-compose.mcp.yml`): MCP server container config for team SSE setups
- **Examples**: Solo agent, multi-agent coordination, and CI agent configurations
- **Postinstall script**: Prints setup instructions after `npm install`
- **Test suite**: Unit tests (skill manifest, MCP config, package structure), integration tests (MCP handshake, auth, tools), E2E tests (solo workflow, event bus, multi-agent, error handling, dependency resolution)
- **CI pipeline**: GitHub Actions workflow with unit → integration → e2e stages
