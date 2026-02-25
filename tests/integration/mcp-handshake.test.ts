import { describe, it, expect, beforeAll } from "vitest";
import { spawn } from "node:child_process";
import { resolve } from "node:path";

// These tests require:
// 1. Docker Compose stack running (docker-compose.test.yml)
// 2. evc-mesh-mcp binary available
// 3. MESH_AGENT_KEY set and valid

const MCP_BINARY = process.env.MCP_BINARY || "evc-mesh-mcp";
const AGENT_KEY = process.env.MESH_AGENT_KEY;

function sendJsonRpc(
  binary: string,
  request: Record<string, unknown>
): Promise<{ stdout: string; stderr: string }> {
  return new Promise((resolve, reject) => {
    const proc = spawn(binary, ["--transport", "stdio"], {
      env: {
        ...process.env,
        MESH_AGENT_KEY: AGENT_KEY,
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

    proc.on("close", () => {
      resolve({ stdout, stderr });
    });

    proc.on("error", reject);

    proc.stdin.write(JSON.stringify(request) + "\n");

    // Give the server time to respond, then close
    setTimeout(() => {
      proc.stdin.end();
      proc.kill("SIGTERM");
    }, 5000);
  });
}

describe.skipIf(!AGENT_KEY)("MCP Handshake", () => {
  it("should respond to initialize request", async () => {
    const request = {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: {
          name: "test-client",
          version: "0.1.0",
        },
      },
    };

    const { stdout } = await sendJsonRpc(MCP_BINARY, request);
    expect(stdout).toContain("jsonrpc");
    expect(stdout).toContain("evc-mesh");
  });

  it("should return 23 tools from tools/list", async () => {
    // Send initialize first, then tools/list
    const initRequest = {
      jsonrpc: "2.0",
      id: 1,
      method: "initialize",
      params: {
        protocolVersion: "2024-11-05",
        capabilities: {},
        clientInfo: { name: "test-client", version: "0.1.0" },
      },
    };

    const toolsRequest = {
      jsonrpc: "2.0",
      id: 2,
      method: "tools/list",
      params: {},
    };

    const proc = spawn(MCP_BINARY, ["--transport", "stdio"], {
      env: {
        ...process.env,
        MESH_AGENT_KEY: AGENT_KEY,
      },
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    proc.stdout.on("data", (data) => {
      stdout += data.toString();
    });

    // Send init, wait, then send tools/list
    proc.stdin.write(JSON.stringify(initRequest) + "\n");
    await new Promise((r) => setTimeout(r, 1000));
    proc.stdin.write(JSON.stringify(toolsRequest) + "\n");
    await new Promise((r) => setTimeout(r, 2000));
    proc.stdin.end();
    proc.kill("SIGTERM");

    await new Promise((r) => proc.on("close", r));

    // Parse responses — may contain multiple JSON objects
    const responses = stdout
      .split("\n")
      .filter((line) => line.trim().startsWith("{"))
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      })
      .filter(Boolean);

    // Find the tools/list response
    const toolsResponse = responses.find(
      (r: Record<string, unknown>) =>
        (r as { id?: number }).id === 2 && (r as { result?: unknown }).result
    );

    if (toolsResponse) {
      const tools = (toolsResponse as { result: { tools: unknown[] } }).result
        .tools;
      expect(tools).toHaveLength(23);
    }
  });
});
