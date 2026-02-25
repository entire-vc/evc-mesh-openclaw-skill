import { describe, it, expect } from "vitest";
import { spawn } from "node:child_process";

const MCP_BINARY = process.env.MCP_BINARY || "evc-mesh-mcp";
const AGENT_KEY = process.env.MESH_AGENT_KEY;

function callMcpTool(
  agentKey: string | undefined,
  toolName: string,
  args: Record<string, unknown>
): Promise<{ stdout: string; stderr: string; exitCode: number | null }> {
  return new Promise((resolve, reject) => {
    const proc = spawn(MCP_BINARY, ["--transport", "stdio"], {
      env: {
        ...process.env,
        MESH_AGENT_KEY: agentKey,
      },
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });
    proc.stderr.on("data", (data) => {
      stderr += data.toString();
    });

    proc.on("close", (code) => {
      resolve({ stdout, stderr, exitCode: code });
    });

    proc.on("error", reject);

    // Send initialize
    const initRequest = {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: { name: "test-auth", version: "0.1.0" },
      },
    };

    proc.stdin.write(JSON.stringify(initRequest) + "\n");

    // Send tool call after a short delay
    setTimeout(() => {
      const toolRequest = {
        jsonrpc: "2.0",
        id: 2,
        method: "tools/call",
        params: {
          name: toolName,
          arguments: args,
        },
      };
      proc.stdin.write(JSON.stringify(toolRequest) + "\n");
    }, 500);

    // Close after response
    setTimeout(() => {
      proc.stdin.end();
      proc.kill("SIGTERM");
    }, 5000);
  });
}

describe.skipIf(!AGENT_KEY)("MCP Auth", () => {
  it("should succeed with valid agent key", async () => {
    const { stdout } = await callMcpTool(AGENT_KEY, "heartbeat", {
      status: "online",
    });
    // Should not contain authentication error
    expect(stdout).not.toContain("authentication");
    expect(stdout).not.toContain("unauthorized");
  });

  it("should fail with invalid agent key", async () => {
    const { stdout, stderr } = await callMcpTool(
      "agk_invalid_000000",
      "heartbeat",
      { status: "online" }
    );
    const output = stdout + stderr;
    // Should contain some form of auth error
    const hasError =
      output.includes("error") ||
      output.includes("unauthorized") ||
      output.includes("authentication") ||
      output.includes("invalid");
    expect(hasError).toBe(true);
  });

  it("should fail with empty agent key", async () => {
    const { stdout, stderr } = await callMcpTool("", "heartbeat", {
      status: "online",
    });
    const output = stdout + stderr;
    const hasError =
      output.includes("error") ||
      output.includes("unauthorized") ||
      output.includes("authentication") ||
      output.includes("invalid") ||
      output.includes("required");
    expect(hasError).toBe(true);
  });
});
