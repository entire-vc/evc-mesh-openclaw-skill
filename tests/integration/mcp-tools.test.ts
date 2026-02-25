import { describe, it, expect } from "vitest";
import { spawn } from "node:child_process";

const MCP_BINARY = process.env.MCP_BINARY || "evc-mesh-mcp";
const AGENT_KEY = process.env.MESH_AGENT_KEY;

/**
 * Canonical list of 23 MCP tools in evc-mesh.
 * Source: internal/mcp/server.go AddTool calls.
 */
const CANONICAL_TOOLS = [
  "list_projects",
  "get_project",
  "list_tasks",
  "get_task",
  "create_task",
  "update_task",
  "move_task",
  "create_subtask",
  "add_dependency",
  "assign_task",
  "add_comment",
  "list_comments",
  "upload_artifact",
  "list_artifacts",
  "get_artifact",
  "publish_event",
  "publish_summary",
  "get_context",
  "get_task_context",
  "subscribe_events",
  "heartbeat",
  "get_my_tasks",
  "report_error",
] as const;

function getToolsList(): Promise<string[]> {
  return new Promise((resolve, reject) => {
    const proc = spawn(MCP_BINARY, ["--transport", "stdio"], {
      env: { ...process.env, MESH_AGENT_KEY: AGENT_KEY },
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });
    proc.on("error", reject);

    // initialize
    proc.stdin.write(
      JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2024-11-05",
          capabilities: {},
          clientInfo: { name: "test-tools", version: "0.1.0" },
        },
      }) + "\n"
    );

    setTimeout(() => {
      proc.stdin.write(
        JSON.stringify({
          jsonrpc: "2.0",
          id: 2,
          method: "tools/list",
          params: {},
        }) + "\n"
      );
    }, 500);

    setTimeout(() => {
      proc.stdin.end();
      proc.kill("SIGTERM");
    }, 3000);

    proc.on("close", () => {
      try {
        const responses = stdout
          .split("\n")
          .filter((l) => l.trim().startsWith("{"))
          .map((l) => {
            try {
              return JSON.parse(l);
            } catch {
              return null;
            }
          })
          .filter(Boolean);

        const toolsResp = responses.find(
          (r: Record<string, unknown>) =>
            (r as { id?: number }).id === 2 &&
            (r as { result?: unknown }).result
        );

        if (toolsResp) {
          const tools = (
            toolsResp as { result: { tools: { name: string }[] } }
          ).result.tools.map((t) => t.name);
          resolve(tools);
        } else {
          resolve([]);
        }
      } catch {
        resolve([]);
      }
    });
  });
}

describe.skipIf(!AGENT_KEY)("MCP Tools", () => {
  it("should return exactly 23 tools", async () => {
    const tools = await getToolsList();
    expect(tools).toHaveLength(23);
  });

  it("should include all canonical tool names", async () => {
    const tools = await getToolsList();
    for (const toolName of CANONICAL_TOOLS) {
      expect(tools, `Missing tool: ${toolName}`).toContain(toolName);
    }
  });

  it("should not have unexpected tools beyond canonical list", async () => {
    const tools = await getToolsList();
    for (const tool of tools) {
      expect(
        CANONICAL_TOOLS as readonly string[],
        `Unexpected tool: ${tool}`
      ).toContain(tool);
    }
  });
});
