---
description: Update dev docs before conversation compaction - capture progress, update tasks, note next steps
---

# Update Dev Docs Before Compaction

You need to update the development documentation to preserve context before the conversation is compacted or ends.

## Your Task

1. **Find Active Dev Docs**
   Look in `dev/active/` for the current task's documentation folder.

2. **Update Tasks File** (`{task-name}-tasks.md`)
   - Mark completed tasks as `[x] DONE`
   - Add any new tasks discovered during implementation
   - Note blockers or issues encountered
   - Update the "Last Updated" timestamp

3. **Update Context File** (`{task-name}-context.md`)
   - Add any new files that were created or modified
   - Document any architectural decisions made
   - Add any new patterns or conventions discovered
   - Note any API changes or data model updates
   - Update the "Last Updated" timestamp

4. **Document Next Steps**
   At the end of the tasks file, add a "## Next Steps" section with:
   - What was the last thing completed?
   - What should be done next?
   - Any blockers or pending decisions?
   - Any notes for the next session?

## Example Update

```markdown
## Next Steps (Session End: 2024-01-15)

**Last Completed:**
- Implemented user authentication endpoint
- Added JWT token generation

**Next Up:**
- Add token refresh endpoint
- Implement logout functionality

**Blockers:**
- Need to decide on token expiration time

**Notes:**
- Consider using refresh tokens for better UX
- Check if we need to store sessions in Redis
```

## Important

- Be thorough - this is your memory for the next session
- Include specific file paths and line numbers where relevant
- Document any temporary workarounds that need cleanup
- Note any questions that came up during implementation
