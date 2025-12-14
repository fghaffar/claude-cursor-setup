---
description: Create a comprehensive strategic plan for a feature or task with context, implementation steps, and task breakdown
---

# Create Dev Docs

You are tasked with creating comprehensive development documentation for implementing a feature or task.

## Your Task

1. **Gather Context**
   - Search the codebase to understand relevant files, patterns, and architecture
   - Identify integration points and dependencies
   - Note any existing patterns or conventions to follow

2. **Create Strategic Plan**
   - Executive Summary: High-level overview of what's being built
   - Phases: Break down into major phases
   - Tasks: Detailed checklist of implementation steps
   - Risks & Considerations: Potential issues and mitigation strategies
   - Success Metrics: How to measure completion

3. **Create Three Files in `dev/active/{task-name}/`**

   **File 1: `{task-name}-plan.md`**
   - The approved strategic plan
   - Include all phases, tasks, and considerations

   **File 2: `{task-name}-context.md`**
   - Key file paths and their purposes
   - Architectural decisions and patterns
   - Integration points
   - Dependencies and prerequisites
   - API contracts or data models
   - Last Updated timestamp

   **File 3: `{task-name}-tasks.md`**
   - Checkbox-style task list
   - Group by phase
   - Include acceptance criteria for each task
   - Mark as [ ] TODO, [x] DONE
   - Last Updated timestamp

## Example Structure

```
dev/active/user-authentication/
  user-authentication-plan.md
  user-authentication-context.md
  user-authentication-tasks.md
```

## Important Guidelines

- Be thorough in gathering context before planning
- Break down tasks into manageable, testable units
- Include error handling and edge cases in tasks
- Note any assumptions being made
- Update timestamps when modifying files
- Keep context file updated with new discoveries

Start by asking clarifying questions if the task description is ambiguous, then proceed with creating the dev docs.
