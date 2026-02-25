import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { parse as parseYaml } from "yaml";

const SKILLS_DIR = resolve(__dirname, "../../skills");

const SKILL_FILES = [
  "evc-mesh.md",
  "evc-mesh-events.md",
  "evc-mesh-coordination.md",
];

const REQUIRED_FRONTMATTER_FIELDS = [
  "name",
  "description",
  "homepage",
  "user-invocable",
  "triggers",
  "metadata",
];

function parseFrontmatter(content: string): Record<string, unknown> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) throw new Error("No YAML frontmatter found");
  return parseYaml(match[1]) as Record<string, unknown>;
}

describe("Skill Manifest Validation", () => {
  for (const file of SKILL_FILES) {
    describe(file, () => {
      const content = readFileSync(resolve(SKILLS_DIR, file), "utf-8");
      const frontmatter = parseFrontmatter(content);

      it("should have valid YAML frontmatter", () => {
        expect(frontmatter).toBeDefined();
        expect(typeof frontmatter).toBe("object");
      });

      for (const field of REQUIRED_FRONTMATTER_FIELDS) {
        it(`should have required field: ${field}`, () => {
          expect(frontmatter).toHaveProperty(field);
        });
      }

      it("should have a string name", () => {
        expect(typeof frontmatter.name).toBe("string");
        expect((frontmatter.name as string).length).toBeGreaterThan(0);
      });

      it("should have a string description", () => {
        expect(typeof frontmatter.description).toBe("string");
        expect((frontmatter.description as string).length).toBeGreaterThan(0);
      });

      it("should have a valid homepage URL", () => {
        expect(typeof frontmatter.homepage).toBe("string");
        expect(frontmatter.homepage).toContain(
          "github.com/entire-vc/evc-mesh-openclaw-skill"
        );
      });

      it("should have a boolean user-invocable", () => {
        expect(typeof frontmatter["user-invocable"]).toBe("boolean");
      });

      it("should have a non-empty triggers array", () => {
        expect(Array.isArray(frontmatter.triggers)).toBe(true);
        expect(
          (frontmatter.triggers as string[]).length
        ).toBeGreaterThanOrEqual(1);
      });

      it("should have valid metadata.openclaw block", () => {
        const metadata = frontmatter.metadata as Record<string, unknown>;
        expect(metadata).toHaveProperty("openclaw");

        const openclaw = metadata.openclaw as Record<string, unknown>;
        expect(openclaw).toHaveProperty("requires");
        expect(openclaw).toHaveProperty("primaryEnv", "MESH_AGENT_KEY");
        expect(openclaw).toHaveProperty("mcpServer", "evc-mesh");

        const requires = openclaw.requires as Record<string, unknown>;
        expect(requires).toHaveProperty("env");
        expect(
          (requires.env as string[]).includes("MESH_AGENT_KEY")
        ).toBe(true);
      });

      it("should have a markdown body after frontmatter", () => {
        const bodyMatch = content.match(/^---\n[\s\S]*?\n---\n([\s\S]+)/);
        expect(bodyMatch).not.toBeNull();
        const body = bodyMatch![1].trim();
        expect(body.length).toBeGreaterThan(100);
      });
    });
  }

  describe("Skill names are unique", () => {
    it("should have unique name values across all skills", () => {
      const names = SKILL_FILES.map((file) => {
        const content = readFileSync(resolve(SKILLS_DIR, file), "utf-8");
        return parseFrontmatter(content).name as string;
      });
      const unique = new Set(names);
      expect(unique.size).toBe(names.length);
    });
  });

  describe("Dependency chain", () => {
    it("evc-mesh-events should depend on evc-mesh", () => {
      const content = readFileSync(
        resolve(SKILLS_DIR, "evc-mesh-events.md"),
        "utf-8"
      );
      const fm = parseFrontmatter(content);
      const openclaw = (fm.metadata as Record<string, unknown>)
        .openclaw as Record<string, unknown>;
      expect(openclaw.dependsOn).toContain("evc-mesh");
    });

    it("evc-mesh-coordination should depend on evc-mesh and evc-mesh-events", () => {
      const content = readFileSync(
        resolve(SKILLS_DIR, "evc-mesh-coordination.md"),
        "utf-8"
      );
      const fm = parseFrontmatter(content);
      const openclaw = (fm.metadata as Record<string, unknown>)
        .openclaw as Record<string, unknown>;
      expect(openclaw.dependsOn).toContain("evc-mesh");
      expect(openclaw.dependsOn).toContain("evc-mesh-events");
    });
  });
});
