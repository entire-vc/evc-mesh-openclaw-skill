import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const CONFIG_DIR = resolve(__dirname, "../../config");

describe("MCP Config Validation", () => {
  describe("openclaw-mcp-stdio.json", () => {
    const raw = readFileSync(
      resolve(CONFIG_DIR, "openclaw-mcp-stdio.json"),
      "utf-8"
    );
    const config = JSON.parse(raw);

    it("should be valid JSON", () => {
      expect(() => JSON.parse(raw)).not.toThrow();
    });

    it("should have mcpServers.evc-mesh key", () => {
      expect(config).toHaveProperty("mcpServers");
      expect(config.mcpServers).toHaveProperty("evc-mesh");
    });

    it("should have command and args for stdio transport", () => {
      const server = config.mcpServers["evc-mesh"];
      expect(server).toHaveProperty("command", "evc-mesh-mcp");
      expect(server).toHaveProperty("args");
      expect(server.args).toContain("stdio");
    });

    it("should have MESH_AGENT_KEY in env", () => {
      const env = config.mcpServers["evc-mesh"].env;
      expect(env).toHaveProperty("MESH_AGENT_KEY");
    });

    it("should use ${VAR} or ${VAR:-default} syntax for env vars", () => {
      const env = config.mcpServers["evc-mesh"].env as Record<string, string>;
      const envVarPattern = /^\$\{[A-Z0-9_]+(?::-[^}]*)?\}$/;

      for (const [key, value] of Object.entries(env)) {
        expect(
          value,
          `env.${key} should use \${VAR} or \${VAR:-default} syntax`
        ).toMatch(envVarPattern);
      }
    });

    it("should have sensible defaults for infrastructure vars", () => {
      const env = config.mcpServers["evc-mesh"].env as Record<string, string>;
      expect(env.DB_HOST).toContain("localhost");
      expect(env.DB_PORT).toContain("5437");
      expect(env.DB_USER).toContain("mesh");
      expect(env.DB_NAME).toContain("mesh");
      expect(env.REDIS_HOST).toContain("localhost");
      expect(env.NATS_URL).toContain("4223");
    });

    it("MESH_AGENT_KEY should have no default (required)", () => {
      const env = config.mcpServers["evc-mesh"].env as Record<string, string>;
      expect(env.MESH_AGENT_KEY).toBe("${MESH_AGENT_KEY}");
      expect(env.MESH_AGENT_KEY).not.toContain(":-");
    });
  });

  describe("openclaw-mcp-sse.json", () => {
    const raw = readFileSync(
      resolve(CONFIG_DIR, "openclaw-mcp-sse.json"),
      "utf-8"
    );
    const config = JSON.parse(raw);

    it("should be valid JSON", () => {
      expect(() => JSON.parse(raw)).not.toThrow();
    });

    it("should have mcpServers.evc-mesh key", () => {
      expect(config).toHaveProperty("mcpServers");
      expect(config.mcpServers).toHaveProperty("evc-mesh");
    });

    it("should specify SSE transport", () => {
      const server = config.mcpServers["evc-mesh"];
      expect(server).toHaveProperty("transport", "sse");
    });

    it("should have url field with default", () => {
      const server = config.mcpServers["evc-mesh"];
      expect(server).toHaveProperty("url");
      expect(server.url).toContain("MESH_MCP_SSE_URL");
      expect(server.url).toContain("8081/mcp/sse");
    });

    it("should have Authorization header with MESH_AGENT_KEY", () => {
      const server = config.mcpServers["evc-mesh"];
      expect(server).toHaveProperty("headers");
      expect(server.headers).toHaveProperty("Authorization");
      expect(server.headers.Authorization).toContain("MESH_AGENT_KEY");
    });

    it("should NOT have command or args (not stdio)", () => {
      const server = config.mcpServers["evc-mesh"];
      expect(server).not.toHaveProperty("command");
      expect(server).not.toHaveProperty("args");
    });
  });
});
