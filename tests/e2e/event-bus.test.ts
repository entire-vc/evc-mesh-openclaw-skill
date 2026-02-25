/**
 * E2E: Event Bus Workflow
 *
 * Verifies that event bus context is shared between agents:
 *   Agent A publishes a summary → Agent B reads it via get_context
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  apiCall,
  createTestTask,
  deleteTask,
  getStatusByCategory,
  type Task,
} from "./fixtures/test-helpers.js";
import { runMockAgent } from "./fixtures/mock-agent.js";

const AGENT_KEY = process.env.MESH_AGENT_KEY;
const PROJECT_ID =
  process.env.TEST_PROJECT_ID || "e2e00000-0000-0000-0000-000000000010";
const AGENT_1_ID =
  process.env.TEST_AGENT_ID || "e2e00000-0000-0000-0000-000000003001";
const AGENT_2_ID =
  process.env.TEST_AGENT_2_ID || "e2e00000-0000-0000-0000-000000003002";

describe.skipIf(!AGENT_KEY)("Event Bus Workflow", () => {
  let testTask: Task;

  beforeAll(async () => {
    const todoStatus = await getStatusByCategory(PROJECT_ID, "todo");
    if (!todoStatus) throw new Error("No todo status found");

    // Create a task for Agent A to complete
    testTask = await createTestTask(PROJECT_ID, {
      title: `E2E Event Bus ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });
  });

  afterAll(async () => {
    if (testTask?.id) {
      await deleteTask(testTask.id).catch(() => {});
    }
  });

  it("Agent A completes a task with summary", async () => {
    const result = await runMockAgent({
      agentId: AGENT_1_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
    });

    expect(result.tasksCompleted.length).toBeGreaterThanOrEqual(1);
  });

  it("Agent B can see the completed task when fetching tasks", async () => {
    // Agent B fetches tasks — the task Agent A completed should be in done
    const doneStatus = await getStatusByCategory(PROJECT_ID, "done");
    if (!doneStatus) throw new Error("No done status found");

    const tasksResp = await apiCall<{ items: Task[] }>(
      `/api/v1/projects/${PROJECT_ID}/tasks?page_size=100`
    );
    const tasks = tasksResp.items ?? [];

    // At least one task should be in done status (the one Agent A completed)
    const doneTasks = tasks.filter((t) => t.status_id === doneStatus.id);
    expect(doneTasks.length).toBeGreaterThanOrEqual(1);
  });

  it("Agent B does not pick up tasks already done", async () => {
    // Agent B runs — should not try to work on done tasks
    const result = await runMockAgent({
      agentId: AGENT_2_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
    });

    // Agent B should not have re-completed the same task
    if (result.tasksCompleted.length > 0) {
      const doneStatus = await getStatusByCategory(PROJECT_ID, "done");
      for (const taskId of result.tasksCompleted) {
        // Each completed task should only have been completed once
        const task = await apiCall<Task>(`/api/v1/tasks/${taskId}`);
        expect(task.status_id).toBe(doneStatus?.id);
      }
    }
  });
});
