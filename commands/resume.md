# Resume Command

Resume development from a handoff document (from Cursor or previous Claude Code session).

## Instructions

When the user runs `/resume`, read the handoff documents and prepare to continue the work.

### Step 1: Read Handoff Documents

Check for handoff documents in this order:
1. `dev/handoff/HANDOFF.md` - Full handoff document
2. `.cursor-handoff` - Condensed handoff from Cursor
3. `dev/active/*/` - Any active dev docs

### Step 2: Analyze Handoff State

From the handoff document, extract:
1. **Current Goal**: What we're working toward
2. **What's Done**: Completed tasks
3. **What's In Progress**: Partially completed work
4. **Next Steps**: What to do next
5. **Key Files**: Files that were modified or need attention
6. **Considerations**: Gotchas, blockers, or important context

### Step 3: Verify Current State

Before resuming, verify:
1. Read the key files mentioned in the handoff
2. Check if any changes were made since the handoff
3. Confirm the next steps are still valid

### Step 4: Present Resume Summary

Output a summary to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 RESUMING FROM HANDOFF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Task**: [task name]
**Handoff From**: [Claude Code / Cursor]
**Handoff Time**: [timestamp]

## What Was Completed
- [completed item 1]
- [completed item 2]

## Current State
[Brief description of where things stand]

## Ready to Continue With
1. [Next action to take]

## Key Files to Review
- `file1.ts` - [brief description]
- `file2.py` - [brief description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Ask for Confirmation

Ask the user:
"Ready to continue with [next action]? Or would you like to review the files first?"

### Step 6: Continue Work

Once confirmed, proceed with the next action from the handoff document.
