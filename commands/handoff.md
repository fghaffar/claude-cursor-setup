# Handoff Command

Generate a handoff document for transitioning between Claude Code and Cursor (or vice versa).

## Instructions

When the user runs `/handoff`, create a comprehensive handoff document that captures the current development state. This enables seamless continuation in another AI coding tool.

### Step 1: Analyze Current Session

Review the conversation to identify:
1. **Primary Goal**: What is the user trying to accomplish?
2. **Completed Work**: What has been done in this session?
3. **In Progress**: What is currently being worked on?
4. **Remaining Tasks**: What still needs to be done?
5. **Key Decisions**: Important architectural or implementation choices made
6. **Files Modified**: List of files created/edited with brief descriptions
7. **Blockers/Considerations**: Any issues, warnings, or things to watch out for

### Step 2: Create Handoff Document

Create/update the file `dev/handoff/HANDOFF.md` with this structure:

```markdown
# Development Handoff

**Generated**: [timestamp]
**From**: [Claude Code / Cursor]
**Task**: [Brief task description]

## Current Goal
[What we're trying to accomplish]

## Session Summary
[2-3 sentence summary of what was done]

## Completed
- [x] Task 1 - Brief description
- [x] Task 2 - Brief description

## In Progress
- [ ] Current task - What's been started, what's left

## Next Steps
1. [Immediate next action]
2. [Following action]
3. [etc.]

## Key Decisions Made
| Decision | Rationale |
|----------|-----------|
| [Choice made] | [Why] |

## Files Modified This Session
| File | Changes |
|------|---------|
| `path/to/file.ts` | Added X, modified Y |

## Context & Considerations
- [Important context point 1]
- [Watch out for X]
- [Remember that Y]

## Code Snippets to Reference
[Any important code patterns or snippets that should be continued]

## Resume Instructions
To continue this work:
1. Read this handoff document
2. Review the files listed above
3. Start with: [specific next action]
```

### Step 3: Also Update .cursor-handoff (for Cursor)

Create/update `.cursor-handoff` in project root - a condensed version Cursor can reference:

```markdown
# ACTIVE TASK HANDOFF

## Current Task
[One line description]

## Status
[What's done, what's next]

## Key Files
- `file1.ts` - [what it does]
- `file2.py` - [what it does]

## Next Action
[Specific thing to do next]

## Watch Out For
- [Gotcha 1]
- [Gotcha 2]
```

### Step 4: Confirm Handoff

Tell the user:
1. Handoff documents created
2. How to continue in the other tool
3. How to resume back in Claude Code
