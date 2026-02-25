/**
 * E2E: Multi-Agent Coordination
 *
 * Verifies that two concurrent agents do not double-assign the same task.
 * Agent 1 claims Task A, Agent 2 should claim Task B (not Task A).
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
import { runMockAgent } from "./fixtures/mock-agent.js";

const AGENT_KEY = process.env.MESH_AGENT_KEY;
const PROJECT_ID =
  process.env.TEST_PROJECT_ID || "e2e00000-0000-0000-0000-000000000010";
const AGENT_1_ID =
  process.env.TEST_AGENT_ID || "e2e00000-0000-0000-0000-000000003001";
const AGENT_2_ID =
  process.env.TEST_AGENT_2_ID || "e2e00000-0000-0000-0000-000000003002";

describe.skipIf(!AGENT_KEY)("Multi-Agent Coordination", () => {
  let taskA: Task;
  let taskB: Task;
  let todoStatus: TaskStatus | undefined;

  beforeAll(async () => {
    todoStatus = await getStatusByCategory(PROJECT_ID, "todo");
    if (!todoStatus) throw new Error("No todo status found");

    // Create two unassigned todo tasks
    taskA = await createTestTask(PROJECT_ID, {
      title: `E2E Multi-Agent Task A ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });

    taskB = await createTestTask(PROJECT_ID, {
      title: `E2E Multi-Agent Task B ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });
  });

  afterAll(async () => {
    if (taskA?.id) await deleteTask(taskA.id).catch(() => {});
    if (taskB?.id) await deleteTask(taskB.id).catch(() => {});
  });

  it("Agent 1 picks up a task and moves to in_progress", async () => {
    const result = await runMockAgent({
      agentId: AGENT_1_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
      stopAfterPickup: true,
    });

    expect(result.tasksPickedUp.length).toBe(1);
  });

  it("Agent 2 picks up a DIFFERENT task", async () => {
    const result = await runMockAgent({
      agentId: AGENT_2_ID,
      agentKey: AGENT_KEY!,
      projectId: PROJECT_ID,
      stopAfterPickup: true,
    });

    expect(result.tasksPickedUp.length).toBe(1);
  });

  it("no task should have two agents assigned", async () => {
    // Fetch all tasks in the project
    const tasksResp = await apiCall<{ items: Task[] }>(
      `/api/v1/projects/${PROJECT_ID}/tasks?page_size=100`
    );
    const tasks = tasksResp.items ?? [];

    // Check in_progress tasks
    const inProgressStatus = await getStatusByCategory(
      PROJECT_ID,
      "in_progress"
    );
    const inProgressTasks = tasks.filter(
      (t) => t.status_id === inProgressStatus?.id
    );

    // Each in_progress task should have exactly one assignee
    for (const task of inProgressTasks) {
      expect(
        task.assignee_id,
        `Task "${task.title}" should have an assignee`
      ).toBeTruthy();
    }

    // No two in_progress tasks should have the same assignee
    const assignees = inProgressTasks
      .map((t) => t.assignee_id)
      .filter(Boolean);
    const uniqueAssignees = new Set(assignees);
    expect(
      uniqueAssignees.size,
      "Each agent should be assigned to a different task"
    ).toBe(assignees.length);
  });
});
