-- Seed data for E2E tests
-- Creates a test workspace, project, statuses, tasks, and two agent keys
-- Run against the test PostgreSQL instance before E2E tests

-- Test workspace
INSERT INTO workspaces (id, name, slug, created_at, updated_at)
VALUES (
  'e2e00000-0000-0000-0000-000000000001',
  'E2E Test Workspace',
  'e2e-test',
  NOW(), NOW()
) ON CONFLICT (id) DO NOTHING;

-- Test project
INSERT INTO projects (id, workspace_id, name, slug, description, created_at, updated_at)
VALUES (
  'e2e00000-0000-0000-0000-000000000010',
  'e2e00000-0000-0000-0000-000000000001',
  'E2E Test Project',
  'e2e-test-project',
  'Project for E2E skill tests',
  NOW(), NOW()
) ON CONFLICT (id) DO NOTHING;

-- Default statuses for test project
INSERT INTO task_statuses (id, project_id, name, slug, category, color, position, created_at, updated_at)
VALUES
  ('e2e00000-0000-0000-0000-000000000100', 'e2e00000-0000-0000-0000-000000000010', 'Backlog', 'backlog', 'backlog', '#6B7280', 0, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000000101', 'e2e00000-0000-0000-0000-000000000010', 'To Do', 'todo', 'todo', '#3B82F6', 1, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000000102', 'e2e00000-0000-0000-0000-000000000010', 'In Progress', 'in-progress', 'in_progress', '#F59E0B', 2, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000000103', 'e2e00000-0000-0000-0000-000000000010', 'Review', 'review', 'review', '#8B5CF6', 3, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000000104', 'e2e00000-0000-0000-0000-000000000010', 'Done', 'done', 'done', '#10B981', 4, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Test tasks (unassigned, in todo)
INSERT INTO tasks (id, project_id, status_id, title, priority, position, created_at, updated_at)
VALUES
  ('e2e00000-0000-0000-0000-000000001001', 'e2e00000-0000-0000-0000-000000000010', 'e2e00000-0000-0000-0000-000000000101', 'High priority test task', 'high', 0, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000001002', 'e2e00000-0000-0000-0000-000000000010', 'e2e00000-0000-0000-0000-000000000101', 'Medium priority test task', 'medium', 1, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000001003', 'e2e00000-0000-0000-0000-000000000010', 'e2e00000-0000-0000-0000-000000000101', 'Low priority test task', 'low', 2, NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000001004', 'e2e00000-0000-0000-0000-000000000010', 'e2e00000-0000-0000-0000-000000000101', 'Blocked task (depends on task A)', 'medium', 3, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Dependency: task 1004 is blocked by task 1001
INSERT INTO task_dependencies (id, task_id, depends_on_id, dependency_type, created_at)
VALUES (
  'e2e00000-0000-0000-0000-000000002001',
  'e2e00000-0000-0000-0000-000000001004',
  'e2e00000-0000-0000-0000-000000001001',
  'blocks',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- Two test agents
-- Note: agent_key_hash should be bcrypt hash of the actual key.
-- For testing, you must register agents via the API and use the returned keys.
-- These rows are placeholders — the real agent registration happens in the test setup.
INSERT INTO agents (id, workspace_id, name, type, status, created_at, updated_at)
VALUES
  ('e2e00000-0000-0000-0000-000000003001', 'e2e00000-0000-0000-0000-000000000001', 'E2E Agent 1', 'openclaw', 'active', NOW(), NOW()),
  ('e2e00000-0000-0000-0000-000000003002', 'e2e00000-0000-0000-0000-000000000001', 'E2E Agent 2', 'openclaw', 'active', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;
