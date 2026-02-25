/**
 * Shared test utilities for E2E tests.
 * Provides HTTP client for REST API, MCP client for tool calls, and assertion helpers.
 */

const API_URL = process.env.MESH_API_URL || "http://localhost:8005";
const AGENT_KEY = process.env.MESH_AGENT_KEY || "";

export interface Task {
  id: string;
  title: string;
  status_id: string;
  status?: { category: string; name: string };
  assignee_id: string | null;
  assignee_type: string | null;
  priority: string;
  position: number;
  labels: string[] | null;
  custom_fields: Record<string, unknown> | null;
}

export interface Project {
  id: string;
  name: string;
  slug: string;
  workspace_id: string;
}

export interface TaskStatus {
  id: string;
  name: string;
  slug: string;
  category: string;
  color: string;
  position: number;
}

export interface Comment {
  id: string;
  task_id: string;
  content: string;
  author_type: string;
}

export interface EventBusEvent {
  id: string;
  event_type: string;
  payload: Record<string, unknown>;
}

/**
 * Make an authenticated API call to the EVC Mesh REST API.
 */
export async function apiCall<T>(
  path: string,
  options: {
    method?: string;
    body?: unknown;
  } = {}
): Promise<T> {
  const { method = "GET", body } = options;
  const url = `${API_URL}${path}`;

  const headers: Record<string, string> = {
    "X-Agent-Key": AGENT_KEY,
    "Content-Type": "application/json",
  };

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`API ${method} ${path} failed (${res.status}): ${text}`);
  }

  return res.json() as Promise<T>;
}

/**
 * Wait for a condition to become true, polling at intervals.
 */
export async function waitFor(
  condition: () => Promise<boolean>,
  options: { timeout?: number; interval?: number; message?: string } = {}
): Promise<void> {
  const { timeout = 10000, interval = 500, message = "condition" } = options;
  const start = Date.now();

  while (Date.now() - start < timeout) {
    if (await condition()) return;
    await new Promise((r) => setTimeout(r, interval));
  }

  throw new Error(`Timed out waiting for ${message} after ${timeout}ms`);
}

/**
 * Assert that a task has a specific status category.
 */
export async function assertTaskStatus(
  taskId: string,
  expectedCategory: string
): Promise<Task> {
  const task = await apiCall<Task>(`/api/v1/tasks/${taskId}`);
  if (task.status?.category !== expectedCategory) {
    throw new Error(
      `Expected task ${taskId} status category to be "${expectedCategory}", got "${task.status?.category}"`
    );
  }
  return task;
}

/**
 * Assert that a task is assigned to a specific agent.
 */
export function assertTaskAssignee(
  task: Task,
  expectedAgentId: string | null
): void {
  if (task.assignee_id !== expectedAgentId) {
    throw new Error(
      `Expected task ${task.id} assignee to be "${expectedAgentId}", got "${task.assignee_id}"`
    );
  }
}

/**
 * Get statuses for a project, grouped by category.
 */
export async function getStatusByCategory(
  projectId: string,
  category: string
): Promise<TaskStatus | undefined> {
  const statuses = await apiCall<TaskStatus[]>(
    `/api/v1/projects/${projectId}/statuses`
  );
  return statuses.find((s) => s.category === category);
}

/**
 * Create a test task with minimal required fields.
 */
export async function createTestTask(
  projectId: string,
  overrides: Partial<{
    title: string;
    priority: string;
    status_id: string;
    assignee_id: string;
    assignee_type: string;
  }> = {}
): Promise<Task> {
  return apiCall<Task>(`/api/v1/projects/${projectId}/tasks`, {
    method: "POST",
    body: {
      title: overrides.title || `Test task ${Date.now()}`,
      priority: overrides.priority || "medium",
      ...overrides,
    },
  });
}

/**
 * Clean up: delete a task (for test teardown).
 */
export async function deleteTask(taskId: string): Promise<void> {
  await apiCall(`/api/v1/tasks/${taskId}`, { method: "DELETE" });
}
