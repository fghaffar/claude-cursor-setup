---
description: Convert an approved plan into dev doc files (plan, context, tasks) in dev/active/ directory
---

# Create Dev Doc Files

You are converting an approved plan into the standard dev docs format.

## Prerequisites

- A plan has been discussed and approved in the conversation
- You know the task name for the directory

## Your Task

Create the following files in `dev/active/{task-name}/`:

### File 1: `{task-name}-plan.md`

```markdown
# {Task Name} - Implementation Plan

## Executive Summary
[High-level overview from the approved plan]

## Phases

### Phase 1: [Phase Name]
[Description and goals]

### Phase 2: [Phase Name]
[Description and goals]

## Risks & Considerations
- [Risk 1]
- [Risk 2]

## Success Metrics
- [Metric 1]
- [Metric 2]

---
**Created**: [Date]
**Status**: In Progress
```

### File 2: `{task-name}-context.md`

```markdown
# {Task Name} - Context

## Key Files

| File | Purpose |
|------|---------|
| `path/to/file.ts` | Description |

## Architecture Decisions
- [Decision 1]
- [Decision 2]

## Integration Points
- [Integration 1]
- [Integration 2]

## Dependencies
- [Dependency 1]
- [Dependency 2]

## API Contracts / Data Models
[Relevant schemas or interfaces]

---
**Last Updated**: [Date]
```

### File 3: `{task-name}-tasks.md`

```markdown
# {Task Name} - Tasks

## Phase 1: [Phase Name]

- [ ] Task 1
  - Acceptance: [Criteria]
- [ ] Task 2
  - Acceptance: [Criteria]

## Phase 2: [Phase Name]

- [ ] Task 3
  - Acceptance: [Criteria]
- [ ] Task 4
  - Acceptance: [Criteria]

## Next Steps

[To be filled in during implementation]

---
**Last Updated**: [Date]
```

## Important

- Create the `dev/active/{task-name}/` directory if it doesn't exist
- Use kebab-case for the task name (e.g., `user-authentication`)
- Extract all information from the approved plan
- Don't add implementation details not in the plan
