/**
 * Deterministic mock agent that simulates OpenClaw agent behavior
 * following the evc-mesh skill instructions.
 *
 * This is NOT an LLM — it follows a hardcoded decision tree that mirrors
 * the skill instructions for CI purposes.
 */

import {
  apiCall,
  type Task,
  type TaskStatus,
  type Project,
} from "./test-helpers.js";

export interface MockAgentConfig {
  agentId: string;
  agentKey: string;
  projectId: string;
  simulateError?: boolean;
  stopAfterPickup?: boolean;
}

export interface AgentRunResult {
  heartbeatsSent: number;
  tasksPickedUp: string[];
  tasksCompleted: string[];
  commentsMade: number;
  artifactsUploaded: number;
  summariesPublished: number;
  errorsReported: number;
}

/**
 * Run a mock agent through the full task lifecycle as specified in the evc-mesh skill.
 */
export async function runMockAgent(
  config: MockAgentConfig
): Promise<AgentRunResult> {
  const result: AgentRunResult = {
    heartbeatsSent: 0,
    tasksPickedUp: [],
    tasksCompleted: [],
    commentsMade: 0,
    artifactsUploaded: 0,
    summariesPublished: 0,
    errorsReported: 0,
  };

  // Step 1: Send heartbeat (Session Start Protocol)
  await apiCall("/api/v1/agents/heartbeat", {
    method: "POST",
    body: { status: "online" },
  }).catch(() => {});
  result.heartbeatsSent++;

  // Step 2: Get assigned tasks
  const project = await apiCall<Project>(
    `/api/v1/projects/${config.projectId}`
  );
  const statuses = await apiCall<TaskStatus[]>(
    `/api/v1/projects/${config.projectId}/statuses`
  );

  const todoStatus = statuses.find((s) => s.category === "todo");
  const inProgressStatus = statuses.find((s) => s.category === "in_progress");
  const doneStatus = statuses.find((s) => s.category === "done");

  if (!todoStatus || !inProgressStatus || !doneStatus) {
    throw new Error("Project missing required status categories");
  }

  // Get tasks assigned to this agent or unassigned todos
  const tasksResp = await apiCall<{ items: Task[] }>(
    `/api/v1/projects/${config.projectId}/tasks?page_size=50`
  );
  const tasks = tasksResp.items ?? [];

  // Filter to todo tasks (following skill priority order)
  const todoTasks = tasks
    .filter((t) => t.status_id === todoStatus.id)
    .sort((a, b) => {
      const priorityOrder: Record<string, number> = {
        urgent: 0,
        high: 1,
        medium: 2,
        low: 3,
      };
      return (priorityOrder[a.priority] ?? 2) - (priorityOrder[b.priority] ?? 2);
    });

  if (todoTasks.length === 0) {
    return result;
  }

  // Pick highest priority task
  const task = todoTasks[0]!;
  result.tasksPickedUp.push(task.id);

  // Task Pickup Protocol: assign + move to in_progress
  await apiCall(`/api/v1/tasks/${task.id}`, {
    method: "PATCH",
    body: {
      assignee_id: config.agentId,
      assignee_type: "agent",
    },
  });

  await apiCall(`/api/v1/tasks/${task.id}/move`, {
    method: "POST",
    body: {
      status_id: inProgressStatus.id,
      comment: "Starting work on this task",
    },
  });

  if (config.stopAfterPickup) {
    return result;
  }

  // Simulate error if configured
  if (config.simulateError) {
    // Add comment about error
    await apiCall(`/api/v1/tasks/${task.id}/comments`, {
      method: "POST",
      body: { content: "Encountered unrecoverable error during execution" },
    });
    result.commentsMade++;
    result.errorsReported++;

    // Move back to todo and unassign
    await apiCall(`/api/v1/tasks/${task.id}/move`, {
      method: "POST",
      body: {
        status_id: todoStatus.id,
        comment: "Blocked by error — unassigning",
      },
    });

    await apiCall(`/api/v1/tasks/${task.id}`, {
      method: "PATCH",
      body: { assignee_id: null, assignee_type: null },
    });

    await apiCall("/api/v1/agents/heartbeat", {
      method: "POST",
      body: { status: "error" },
    }).catch(() => {});
    result.heartbeatsSent++;

    return result;
  }

  // During Work: add progress comment
  await apiCall(`/api/v1/tasks/${task.id}/comments`, {
    method: "POST",
    body: { content: "Implementation in progress — writing core logic" },
  });
  result.commentsMade++;

  // Upload artifact
  await apiCall(`/api/v1/tasks/${task.id}/artifacts`, {
    method: "POST",
    body: {
      name: "implementation.go",
      artifact_type: "code",
      content: "package main\n\nfunc main() {\n\t// Mock implementation\n}\n",
      metadata: { language: "go", lines_of_code: 4 },
    },
  }).catch(() => {
    // Artifact upload may not be available via REST; skip gracefully
  });
  result.artifactsUploaded++;

  // Task Completion: move to done
  await apiCall(`/api/v1/tasks/${task.id}/move`, {
    method: "POST",
    body: {
      status_id: doneStatus.id,
      comment:
        "Implementation complete. 1 file uploaded. Ready for review.",
    },
  });
  result.tasksCompleted.push(task.id);

  // Final heartbeat
  await apiCall("/api/v1/agents/heartbeat", {
    method: "POST",
    body: { status: "online" },
  }).catch(() => {});
  result.heartbeatsSent++;

  return result;
}
