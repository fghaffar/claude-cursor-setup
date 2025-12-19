#!/bin/bash

# Handoff Management Script
# Auto-generates handoff documents from git state and optional context
# Designed to work non-interactively when Claude Code hits rate limits

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

HANDOFF_DIR="dev/handoff"
HANDOFF_FILE="$HANDOFF_DIR/HANDOFF.md"
CURSOR_HANDOFF=".cursor-handoff"
ARCHIVE_DIR="$HANDOFF_DIR/archive"

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

show_help() {
    cat << 'EOF'
Handoff Management - Transition between Claude Code and Cursor

RECOMMENDED WORKFLOW:
  1. In Claude Code, BEFORE hitting rate limit, run: /handoff
     (Claude Code creates rich handoff from session context)
  2. Switch to Cursor, say: "Resume from handoff"
  3. When done in Cursor, run: ./handoff.sh auto "status update"
  4. Switch back to Claude Code, run: /resume

This script is for:
  - Emergency fallback if you forgot to run /handoff
  - Creating handoffs when switching FROM Cursor back to Claude Code
  - Checking handoff status

Usage: ./handoff.sh [command] [options]

Commands:
  auto [task] [context]   Generate handoff from git state (fallback/Cursor use)
  status                  Show current handoff status
  archive                 Archive current handoff
  history                 Show handoff history
  help                    Show this help

Examples:
  ./handoff.sh auto "Building user dashboard" "Auth done, need UI"
  ./handoff.sh status
  ./handoff.sh  # Same as 'auto' with no args

Note: The /handoff command in Claude Code produces MUCH richer context
since it has access to the full conversation history. Use this script
only as a fallback or when switching FROM Cursor.
EOF
}

ensure_dirs() {
    mkdir -p "$HANDOFF_DIR"
    mkdir -p "$ARCHIVE_DIR"
}

# Get modified files from git
get_modified_files() {
    local files=""
    
    # Staged files
    staged=$(git diff --cached --name-only 2>/dev/null || echo "")
    
    # Unstaged modified files
    unstaged=$(git diff --name-only 2>/dev/null || echo "")
    
    # Untracked files
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")
    
    # Combine unique
    echo "$staged"$'\n'"$unstaged"$'\n'"$untracked" | sort -u | grep -v '^$' || echo ""
}

# Get recent commits (last 5)
get_recent_commits() {
    git log --oneline -5 2>/dev/null || echo "No commits found"
}

# Get uncommitted changes summary
get_changes_summary() {
    local summary=""
    
    # Count of changes
    local staged_count=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    local unstaged_count=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')
    local untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    
    echo "Staged: $staged_count files, Unstaged: $unstaged_count files, Untracked: $untracked_count files"
}

# Get current branch
get_branch() {
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Get diff stats
get_diff_stats() {
    git diff --stat 2>/dev/null | tail -1 || echo ""
}

# Auto-generate handoff from git state
auto_handoff() {
    ensure_dirs
    
    local task="${1:-}"
    local context="${2:-}"
    
    print_header "Auto-generating Handoff"
    
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    BRANCH=$(get_branch)
    MODIFIED_FILES=$(get_modified_files)
    RECENT_COMMITS=$(get_recent_commits)
    CHANGES_SUMMARY=$(get_changes_summary)
    DIFF_STATS=$(get_diff_stats)
    
    # Build files table
    FILES_TABLE=""
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            # Get file status
            if git diff --cached --name-only | grep -q "^$file$" 2>/dev/null; then
                status="staged"
            elif git diff --name-only | grep -q "^$file$" 2>/dev/null; then
                status="modified"
            else
                status="new/untracked"
            fi
            FILES_TABLE="$FILES_TABLE| \`$file\` | $status |\n"
        fi
    done <<< "$MODIFIED_FILES"
    
    # If no task provided, try to infer from recent commit
    if [ -z "$task" ]; then
        task=$(git log --oneline -1 --format="%s" 2>/dev/null || echo "Continuing development")
    fi
    
    # Create main handoff file
    cat > "$HANDOFF_FILE" << EOF
# Development Handoff

**Generated**: $TIMESTAMP
**From**: Claude Code (auto-generated)
**Branch**: $BRANCH
**Task**: $task

## Current Goal
$task

## Session Context
${context:-"Auto-generated from git state. Review files and commits below for context."}

## Git State Summary
$CHANGES_SUMMARY
${DIFF_STATS:+
**Diff Stats**: $DIFF_STATS}

## Recent Commits
\`\`\`
$RECENT_COMMITS
\`\`\`

## Files Modified/Pending
| File | Status |
|------|--------|
$(echo -e "$FILES_TABLE")

## Uncommitted Changes
$(if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "\`\`\`"
    git status --short 2>/dev/null
    echo "\`\`\`"
else
    echo "No uncommitted changes"
fi)

## Resume Instructions
1. Read this handoff document
2. Check \`git status\` and \`git diff\` for current state
3. Review the modified files listed above
4. Continue with the task: $task
EOF

    # Create cursor-friendly version
    cat > "$CURSOR_HANDOFF" << EOF
# ACTIVE TASK HANDOFF

**Task**: $task
**From**: Claude Code
**Time**: $TIMESTAMP
**Branch**: $BRANCH

## Git State
$CHANGES_SUMMARY

## Key Files
$(echo -e "$FILES_TABLE" | head -10)

## Context
${context:-"Check git status and recent commits for context."}

## Recent Commits
$RECENT_COMMITS

## Next Action
Continue with: $task
Review \`git diff\` to see current changes.

---
## Instructions for Cursor
Start with: "I'm resuming from a handoff. Let me check the git state and modified files..."
For full details see: dev/handoff/HANDOFF.md
EOF

    echo -e "${GREEN}Handoff generated from git state${NC}"
    echo ""
    echo -e "Branch: ${CYAN}$BRANCH${NC}"
    echo -e "Task: ${CYAN}$task${NC}"
    echo -e "Changes: ${CYAN}$CHANGES_SUMMARY${NC}"
    echo ""
    echo -e "${GREEN}Created:${NC}"
    echo "  - $HANDOFF_FILE"
    echo "  - $CURSOR_HANDOFF"
    echo ""
    echo -e "${YELLOW}In Cursor, start with:${NC}"
    echo -e "${CYAN}\"Resume from handoff - read .cursor-handoff and git status\"${NC}"
}

show_status() {
    print_header "Handoff Status"

    if [ -f "$HANDOFF_FILE" ]; then
        echo -e "${GREEN}Active handoff found:${NC}"
        echo ""
        head -30 "$HANDOFF_FILE"
        echo ""
        echo -e "${CYAN}... (use 'cat $HANDOFF_FILE' for full content)${NC}"
    else
        echo -e "${YELLOW}No active handoff found${NC}"
    fi

    echo ""

    if [ -f "$CURSOR_HANDOFF" ]; then
        echo -e "${GREEN}Cursor handoff exists:${NC} $CURSOR_HANDOFF"
    fi
    
    echo ""
    echo -e "${BLUE}Current git state:${NC}"
    get_changes_summary
}

archive_handoff() {
    ensure_dirs

    if [ -f "$HANDOFF_FILE" ]; then
        ARCHIVE_NAME="handoff-$(date +%Y%m%d-%H%M%S).md"
        mv "$HANDOFF_FILE" "$ARCHIVE_DIR/$ARCHIVE_NAME"
        echo -e "${GREEN}Archived to $ARCHIVE_DIR/$ARCHIVE_NAME${NC}"
    fi

    if [ -f "$CURSOR_HANDOFF" ]; then
        rm "$CURSOR_HANDOFF"
        echo -e "${GREEN}Removed $CURSOR_HANDOFF${NC}"
    fi
}

show_history() {
    ensure_dirs

    print_header "Handoff History"

    if [ -d "$ARCHIVE_DIR" ] && [ "$(ls -A $ARCHIVE_DIR 2>/dev/null)" ]; then
        ls -la "$ARCHIVE_DIR"/*.md 2>/dev/null
    else
        echo -e "${YELLOW}No archived handoffs${NC}"
    fi
}

# Main
case "${1:-auto}" in
    auto)
        auto_handoff "$2" "$3"
        ;;
    status)
        show_status
        ;;
    archive)
        archive_handoff
        ;;
    history)
        show_history
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        # Treat unknown first arg as task description
        auto_handoff "$1" "$2"
        ;;
esac
