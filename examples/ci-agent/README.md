# CI Agent Example

An OpenClaw agent that runs tests and reports results to EVC Mesh via the event bus. Uses SSE transport for remote connection to the MCP server.

## Prerequisites

1. EVC Mesh deployed with MCP SSE endpoint available
2. An agent registered in EVC Mesh with an API key
3. OpenClaw installed

## Setup

```bash
# Set environment
export MESH_AGENT_KEY="agk_your_workspace_key"
export MESH_MCP_SSE_URL="https://mesh.your-domain.com/mcp/sse"

# Copy this openclaw.json to your CI workspace
cp openclaw.json /path/to/ci/workspace/
```

## Agent Behavior

This CI agent uses SSE transport (no local binary needed) and:

1. Monitors for tasks entering `review` status via `get_context` polling
2. Downloads code artifacts with `get_artifact`
3. Runs the test suite locally
4. Uploads test results as `log` artifacts
5. Publishes a `custom` event with test results:
   ```json
   {
     "event_name": "test_suite_completed",
     "data": {
       "passed": 578,
       "failed": 0,
       "coverage_pct": 87,
       "commit": "abc1234"
     }
   }
   ```
6. Moves the task forward if tests pass, or back to `in_progress` with failure details

## Why SSE Transport?

CI agents typically run in environments where:
- The MCP server binary is not available locally
- Network access to the MCP SSE endpoint is available
- The agent is ephemeral (container, GitHub Actions runner)

SSE transport connects over HTTP, requiring only `MESH_AGENT_KEY` and `MESH_MCP_SSE_URL`.
