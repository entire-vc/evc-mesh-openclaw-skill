/**
 * E2E: Error Handling
 *
 * Verifies the error recovery flow:
 *   agent picks up task → simulates error → moves back to todo → unassigns
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

describe.skipIf(!AGENT_KEY)("Error Handling", () => {
  let testTask: Task;
  let todoStatus: TaskStatus | undefined;
  let agentResult: AgentRunResult;

  beforeAll(async () => {
    todoStatus = await getStatusByCategory(PROJECT_ID, "todo");
    if (!todoStatus) throw new Error("No todo status found");

    // Create a task for the agent
    testTask = await createTestTask(PROJECT_ID, {
      title: `E2E Error Handling ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });

    // Run agent with error simulation
    agentResult = await runMockAgent({
      agentId: AGENT_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
      simulateError: true,
    });
  });

  afterAll(async () => {
    if (testTask?.id) {
      await deleteTask(testTask.id).catch(() => {});
    }
  });

  it("agent should have picked up the task", () => {
    expect(agentResult.tasksPickedUp.length).toBeGreaterThanOrEqual(1);
  });

  it("agent should have reported an error", () => {
    expect(agentResult.errorsReported).toBeGreaterThanOrEqual(1);
  });

  it("agent should NOT have completed any tasks", () => {
    expect(agentResult.tasksCompleted).toHaveLength(0);
  });

  it("task should be back in todo status", async () => {
    if (agentResult.tasksPickedUp.length === 0) return;

    const taskId = agentResult.tasksPickedUp[0]!;
    const task = await apiCall<Task>(`/api/v1/tasks/${taskId}`);
    expect(task.status_id).toBe(todoStatus?.id);
  });

  it("task should be unassigned", async () => {
    if (agentResult.tasksPickedUp.length === 0) return;

    const taskId = agentResult.tasksPickedUp[0]!;
    const task = await apiCall<Task>(`/api/v1/tasks/${taskId}`);
    expect(task.assignee_id).toBeNull();
  });

  it("task should have an error comment", async () => {
    if (agentResult.tasksPickedUp.length === 0) return;

    const taskId = agentResult.tasksPickedUp[0]!;
    const commentsResp = await apiCall<{ items: { content: string }[] }>(
      `/api/v1/tasks/${taskId}/comments`
    );
    const comments = commentsResp.items ?? [];

    const hasErrorComment = comments.some(
      (c) =>
        c.content.toLowerCase().includes("error") ||
        c.content.toLowerCase().includes("blocked")
    );
    expect(hasErrorComment).toBe(true);
  });
});
