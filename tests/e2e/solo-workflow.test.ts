/**
 * E2E: Solo Agent Workflow
 *
 * Verifies that a single agent can complete a full task lifecycle
 * as specified in the evc-mesh skill:
 *   heartbeat → get tasks → pick up → work → complete → heartbeat
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  apiCall,
  createTestTask,
  deleteTask,
  getStatusByCategory,
  type Task,
  type TaskStatus,
} from "./fixtures/test-helpers.js";
import { runMockAgent, type AgentRunResult } from "./fixtures/mock-agent.js";

const AGENT_KEY = process.env.MESH_AGENT_KEY;
const PROJECT_ID =
  process.env.TEST_PROJECT_ID || "e2e00000-0000-0000-0000-000000000010";
const AGENT_ID =
  process.env.TEST_AGENT_ID || "e2e00000-0000-0000-0000-000000003001";

describe.skipIf(!AGENT_KEY)("Solo Agent Workflow", () => {
  let testTask: Task;
  let todoStatus: TaskStatus | undefined;
  let agentResult: AgentRunResult;

  beforeAll(async () => {
    // Get todo status for task creation
    todoStatus = await getStatusByCategory(PROJECT_ID, "todo");
    if (!todoStatus) throw new Error("No todo status found in project");

    // Create a test task
    testTask = await createTestTask(PROJECT_ID, {
      title: `E2E Solo Workflow ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });

    // Run the mock agent
    agentResult = await runMockAgent({
      agentId: AGENT_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
    });
  });

  afterAll(async () => {
    // Clean up test task
    if (testTask?.id) {
      await deleteTask(testTask.id).catch(() => {});
    }
  });

  it("should have sent at least 2 heartbeats (start + end)", () => {
    expect(agentResult.heartbeatsSent).toBeGreaterThanOrEqual(2);
  });

  it("should have picked up at least one task", () => {
    expect(agentResult.tasksPickedUp.length).toBeGreaterThanOrEqual(1);
  });

  it("should have completed at least one task", () => {
    expect(agentResult.tasksCompleted.length).toBeGreaterThanOrEqual(1);
  });

  it("should have added at least one comment", () => {
    expect(agentResult.commentsMade).toBeGreaterThanOrEqual(1);
  });

  it("completed task should be in done status", async () => {
    if (agentResult.tasksCompleted.length === 0) return;

    const taskId = agentResult.tasksCompleted[0]!;
    const task = await apiCall<Task>(`/api/v1/tasks/${taskId}`);
    const doneStatus = await getStatusByCategory(PROJECT_ID, "done");

    expect(task.status_id).toBe(doneStatus?.id);
  });

  it("completed task should have comments", async () => {
    if (agentResult.tasksCompleted.length === 0) return;

    const taskId = agentResult.tasksCompleted[0]!;
    const commentsResp = await apiCall<{ items: unknown[] }>(
      `/api/v1/tasks/${taskId}/comments`
    );
    const comments = commentsResp.items ?? [];
    expect(comments.length).toBeGreaterThanOrEqual(1);
  });
});
