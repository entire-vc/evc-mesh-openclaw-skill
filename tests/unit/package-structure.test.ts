import { describe, it, expect } from "vitest";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const ROOT = resolve(__dirname, "../..");

describe("Package Structure Validation", () => {
  describe("package.json", () => {
    const pkg = JSON.parse(
      readFileSync(resolve(ROOT, "package.json"), "utf-8")
    );

    it("should have correct package name", () => {
      expect(pkg.name).toBe("@entire-vc/evc-mesh-openclaw-skill");
    });

    it("should have MIT license", () => {
      expect(pkg.license).toBe("MIT");
    });

    it("should have version in semver format", () => {
      expect(pkg.version).toMatch(/^\d+\.\d+\.\d+/);
    });

    it("should have required keywords", () => {
      expect(pkg.keywords).toContain("openclaw");
      expect(pkg.keywords).toContain("evc-mesh");
      expect(pkg.keywords).toContain("mcp");
    });

    it("should have repository URL", () => {
      expect(pkg.repository.url).toContain("evc-mesh-openclaw-skill");
    });

    it("should require Node.js 18+", () => {
      expect(pkg.engines.node).toMatch(/>=\s*18/);
    });

    it("should have openclaw manifest", () => {
      expect(pkg.openclaw).toBeDefined();
      expect(pkg.openclaw.skills).toHaveLength(3);
      expect(pkg.openclaw.mcpServers).toHaveLength(1);
    });

    it("openclaw skills should reference existing files", () => {
      for (const skill of pkg.openclaw.skills) {
        const path = resolve(ROOT, skill.file);
        expect(existsSync(path), `${skill.file} should exist`).toBe(true);
      }
    });

    it("openclaw mcpServers should reference existing config files", () => {
      for (const server of pkg.openclaw.mcpServers) {
        for (const [, file] of Object.entries(server.configFiles)) {
          const path = resolve(ROOT, file as string);
          expect(existsSync(path), `${file} should exist`).toBe(true);
        }
      }
    });
  });

  describe("files array completeness", () => {
    const pkg = JSON.parse(
      readFileSync(resolve(ROOT, "package.json"), "utf-8")
    );

    it("every directory in files array should exist", () => {
      for (const pattern of pkg.files) {
        const dir = pattern.replace(/\/$/, "");
        const path = resolve(ROOT, dir);
        expect(existsSync(path), `${dir}/ should exist`).toBe(true);
      }
    });
  });

  describe("skills/ directory", () => {
    const skillsDir = resolve(ROOT, "skills");

    it("should contain exactly 3 .md files", () => {
      const files = readdirSync(skillsDir).filter((f) => f.endsWith(".md"));
      expect(files).toHaveLength(3);
    });

    it("should contain evc-mesh.md", () => {
      expect(existsSync(resolve(skillsDir, "evc-mesh.md"))).toBe(true);
    });

    it("should contain evc-mesh-events.md", () => {
      expect(existsSync(resolve(skillsDir, "evc-mesh-events.md"))).toBe(true);
    });

    it("should contain evc-mesh-coordination.md", () => {
      expect(existsSync(resolve(skillsDir, "evc-mesh-coordination.md"))).toBe(
        true
      );
    });
  });

  describe("config/ directory", () => {
    const configDir = resolve(ROOT, "config");

    it("should contain openclaw-mcp-stdio.json", () => {
      expect(existsSync(resolve(configDir, "openclaw-mcp-stdio.json"))).toBe(
        true
      );
    });

    it("should contain openclaw-mcp-sse.json", () => {
      expect(existsSync(resolve(configDir, "openclaw-mcp-sse.json"))).toBe(
        true
      );
    });

    it("should contain docker-compose.mcp.yml", () => {
      expect(existsSync(resolve(configDir, "docker-compose.mcp.yml"))).toBe(
        true
      );
    });
  });

  describe("required root files", () => {
    it("should have LICENSE", () => {
      expect(existsSync(resolve(ROOT, "LICENSE"))).toBe(true);
    });

    it("should have README.md", () => {
      expect(existsSync(resolve(ROOT, "README.md"))).toBe(true);
    });

    it("should have CHANGELOG.md", () => {
      expect(existsSync(resolve(ROOT, "CHANGELOG.md"))).toBe(true);
    });

    it("LICENSE should be MIT", () => {
      const license = readFileSync(resolve(ROOT, "LICENSE"), "utf-8");
      expect(license).toContain("MIT License");
    });
  });

  describe("examples/", () => {
    const examplesDir = resolve(ROOT, "examples");

    for (const example of ["solo-agent", "multi-agent", "ci-agent"]) {
      it(`should have ${example}/ with openclaw.json and README.md`, () => {
        const dir = resolve(examplesDir, example);
        expect(existsSync(resolve(dir, "openclaw.json"))).toBe(true);
        expect(existsSync(resolve(dir, "README.md"))).toBe(true);
      });
    }
  });
});
