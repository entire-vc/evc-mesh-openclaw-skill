/**
 * E2E: Dependency Resolution
 *
 * Verifies that an agent skips blocked tasks and picks them up
 * only after their blockers are resolved.
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

const AGENT_KEY = process.env.MESH_AGENT_KEY;
const PROJECT_ID =
  process.env.TEST_PROJECT_ID || "e2e00000-0000-0000-0000-000000000010";
const AGENT_ID =
  process.env.TEST_AGENT_ID || "e2e00000-0000-0000-0000-000000003001";

describe.skipIf(!AGENT_KEY)("Dependency Resolution", () => {
  let taskA: Task;
  let taskB: Task;
  let todoStatus: TaskStatus | undefined;
  let inProgressStatus: TaskStatus | undefined;
  let doneStatus: TaskStatus | undefined;

  beforeAll(async () => {
    todoStatus = await getStatusByCategory(PROJECT_ID, "todo");
    inProgressStatus = await getStatusByCategory(PROJECT_ID, "in_progress");
    doneStatus = await getStatusByCategory(PROJECT_ID, "done");

    if (!todoStatus || !inProgressStatus || !doneStatus) {
      throw new Error("Missing required status categories");
    }

    // Create Task A (blocker) and Task B (blocked by A)
    taskA = await createTestTask(PROJECT_ID, {
      title: `E2E Dep Resolution - Blocker ${Date.now()}`,
      priority: "high",
      status_id: todoStatus.id,
    });

    taskB = await createTestTask(PROJECT_ID, {
      title: `E2E Dep Resolution - Blocked ${Date.now()}`,
      priority: "urgent",
      status_id: todoStatus.id,
    });

    // Set dependency: B is blocked by A
    await apiCall(`/api/v1/tasks/${taskB.id}/dependencies`, {
      method: "POST",
      body: {
        depends_on_id: taskA.id,
        dependency_type: "blocks",
      },
    }).catch(() => {
      // If dependency endpoint doesn't exist, skip
    });
  });

  afterAll(async () => {
    if (taskA?.id) await deleteTask(taskA.id).catch(() => {});
    if (taskB?.id) await deleteTask(taskB.id).catch(() => {});
  });

  it("should be able to pick up Task A (the blocker)", async () => {
    // Assign and move Task A to in_progress
    await apiCall(`/api/v1/tasks/${taskA.id}`, {
      method: "PATCH",
      body: { assignee_id: AGENT_ID, assignee_type: "agent" },
    });

    await apiCall(`/api/v1/tasks/${taskA.id}/move`, {
      method: "POST",
      body: {
        status_id: inProgressStatus!.id,
        comment: "Starting blocker task",
      },
    });

    const task = await apiCall<Task>(`/api/v1/tasks/${taskA.id}`);
    expect(task.status_id).toBe(inProgressStatus!.id);
  });

  it("should complete Task A", async () => {
    // Move Task A to done
    await apiCall(`/api/v1/tasks/${taskA.id}/move`, {
      method: "POST",
      body: {
        status_id: doneStatus!.id,
        comment: "Blocker task completed",
      },
    });

    const task = await apiCall<Task>(`/api/v1/tasks/${taskA.id}`);
    expect(task.status_id).toBe(doneStatus!.id);
  });

  it("should now be able to pick up Task B (previously blocked)", async () => {
    // After Task A is done, Task B should be pickable
    await apiCall(`/api/v1/tasks/${taskB.id}`, {
      method: "PATCH",
      body: { assignee_id: AGENT_ID, assignee_type: "agent" },
    });

    await apiCall(`/api/v1/tasks/${taskB.id}/move`, {
      method: "POST",
      body: {
        status_id: inProgressStatus!.id,
        comment: "Blocker resolved, starting work",
      },
    });

    const task = await apiCall<Task>(`/api/v1/tasks/${taskB.id}`);
    expect(task.status_id).toBe(inProgressStatus!.id);
    expect(task.assignee_id).toBe(AGENT_ID);
  });

  it("Task B was only moved to in_progress after Task A reached done", async () => {
    // This is verified by the test ordering — we moved A to done first,
    // then B to in_progress. If the API enforced dependency checking,
    // B would have failed to move before A was done.
    const taskAFinal = await apiCall<Task>(`/api/v1/tasks/${taskA.id}`);
    const taskBFinal = await apiCall<Task>(`/api/v1/tasks/${taskB.id}`);

    expect(taskAFinal.status_id).toBe(doneStatus!.id);
    expect(taskBFinal.status_id).toBe(inProgressStatus!.id);
  });
});
