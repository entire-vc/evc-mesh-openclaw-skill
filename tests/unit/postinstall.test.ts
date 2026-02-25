import { describe, it, expect } from "vitest";
import { spawnSync } from "node:child_process";
import { resolve } from "node:path";

const SCRIPT_PATH = resolve(__dirname, "../../scripts/postinstall.js");

describe("Postinstall Script", () => {
  it("should run without throwing", () => {
    const result = spawnSync("node", [SCRIPT_PATH], {
      encoding: "utf-8",
      timeout: 5000,
    });
    expect(result.status).toBe(0);
    expect(result.error).toBeUndefined();
  });

  it("should mention MESH_AGENT_KEY in output", () => {
    const result = spawnSync("node", [SCRIPT_PATH], {
      encoding: "utf-8",
      timeout: 5000,
    });
    expect(result.stdout).toContain("MESH_AGENT_KEY");
  });

  it("should mention openclaw mcp add in output", () => {
    const result = spawnSync("node", [SCRIPT_PATH], {
      encoding: "utf-8",
      timeout: 5000,
    });
    expect(result.stdout).toContain("openclaw mcp add");
  });

  it("should mention skill installation in output", () => {
    const result = spawnSync("node", [SCRIPT_PATH], {
      encoding: "utf-8",
      timeout: 5000,
    });
    expect(result.stdout).toContain("openclaw skill install");
  });

  it("should mention the documentation URL", () => {
    const result = spawnSync("node", [SCRIPT_PATH], {
      encoding: "utf-8",
      timeout: 5000,
    });
    expect(result.stdout).toContain(
      "github.com/entire-vc/evc-mesh-openclaw-skill"
    );
  });
});
