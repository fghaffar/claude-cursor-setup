#!/bin/bash

# Handoff Management Script
# Manages transitions between Claude Code and Cursor

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
    echo "Handoff Management - Transition between Claude Code and Cursor"
    echo ""
    echo "Usage: ./handoff.sh [command]"
    echo ""
    echo "Commands:"
    echo "  new       Create a new handoff document interactively"
    echo "  quick     Quick handoff with minimal prompts"
    echo "  status    Show current handoff status"
    echo "  archive   Archive current handoff and start fresh"
    echo "  history   Show handoff history"
    echo "  cursor    Prepare handoff for Cursor (creates .cursor-handoff)"
    echo "  claude    Prepare handoff for Claude Code"
    echo "  help      Show this help"
    echo ""
    echo "Workflow:"
    echo "  1. Working in Claude Code, hit rate limit"
    echo "  2. Run: /handoff (in Claude Code) OR ./handoff.sh quick"
    echo "  3. Switch to Cursor, start with: 'Resume from handoff'"
    echo "  4. When done in Cursor, run: ./handoff.sh quick"
    echo "  5. Switch back to Claude Code, run: /resume"
}

ensure_dirs() {
    mkdir -p "$HANDOFF_DIR"
    mkdir -p "$ARCHIVE_DIR"
}

create_handoff() {
    ensure_dirs

    print_header "Create Handoff Document"

    read -p "Task/Goal (one line): " TASK
    read -p "Source tool (claude/cursor): " SOURCE

    echo "What's completed? (one item per line, empty line to finish):"
    COMPLETED=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        COMPLETED="$COMPLETED- [x] $line\n"
    done

    echo "What's in progress? (one line): "
    read -r IN_PROGRESS

    echo "Next steps? (one item per line, empty line to finish):"
    NEXT_STEPS=""
    STEP_NUM=1
    while IFS= read -r line; do
        [ -z "$line" ] && break
        NEXT_STEPS="$NEXT_STEPS$STEP_NUM. $line\n"
        ((STEP_NUM++))
    done

    echo "Key files modified? (one per line, empty line to finish):"
    FILES=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        FILES="$FILES| \`$line\` | |\n"
    done

    echo "Any gotchas/considerations? (one per line, empty line to finish):"
    CONSIDERATIONS=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        CONSIDERATIONS="$CONSIDERATIONS- $line\n"
    done

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    cat > "$HANDOFF_FILE" << EOF
# Development Handoff

**Generated**: $TIMESTAMP
**From**: $SOURCE
**Task**: $TASK

## Current Goal
$TASK

## Completed
$(echo -e "$COMPLETED")

## In Progress
- [ ] $IN_PROGRESS

## Next Steps
$(echo -e "$NEXT_STEPS")

## Files Modified
| File | Changes |
|------|---------|
$(echo -e "$FILES")

## Considerations
$(echo -e "$CONSIDERATIONS")

## Resume Instructions
1. Read this handoff document
2. Review the files listed above
3. Continue with the next steps
EOF

    echo -e "${GREEN}✓ Created $HANDOFF_FILE${NC}"

    # Also create cursor handoff
    create_cursor_handoff "$TASK" "$IN_PROGRESS" "$NEXT_STEPS"
}

quick_handoff() {
    ensure_dirs

    print_header "Quick Handoff"

    read -p "Task (one line): " TASK
    read -p "What's done (brief): " DONE
    read -p "Next action (specific): " NEXT
    read -p "Source (claude/cursor) [claude]: " SOURCE
    SOURCE=${SOURCE:-claude}

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    cat > "$HANDOFF_FILE" << EOF
# Development Handoff

**Generated**: $TIMESTAMP
**From**: $SOURCE
**Task**: $TASK

## Summary
$DONE

## Next Action
$NEXT

## Resume Instructions
Continue with: $NEXT
EOF

    cat > "$CURSOR_HANDOFF" << EOF
# ACTIVE TASK HANDOFF

**Task**: $TASK
**From**: $SOURCE
**Time**: $TIMESTAMP

## Status
$DONE

## Next Action
$NEXT
EOF

    echo -e "${GREEN}✓ Created handoff files${NC}"
    echo -e "  - $HANDOFF_FILE"
    echo -e "  - $CURSOR_HANDOFF"
}

show_status() {
    print_header "Handoff Status"

    if [ -f "$HANDOFF_FILE" ]; then
        echo -e "${GREEN}Active handoff found:${NC}"
        echo ""
        head -20 "$HANDOFF_FILE"
        echo ""
        echo -e "${CYAN}... (use 'cat $HANDOFF_FILE' for full content)${NC}"
    else
        echo -e "${YELLOW}No active handoff found${NC}"
    fi

    echo ""

    if [ -f "$CURSOR_HANDOFF" ]; then
        echo -e "${GREEN}Cursor handoff found:${NC}"
        cat "$CURSOR_HANDOFF"
    fi
}

archive_handoff() {
    ensure_dirs

    if [ -f "$HANDOFF_FILE" ]; then
        ARCHIVE_NAME="handoff-$(date +%Y%m%d-%H%M%S).md"
        mv "$HANDOFF_FILE" "$ARCHIVE_DIR/$ARCHIVE_NAME"
        echo -e "${GREEN}✓ Archived to $ARCHIVE_DIR/$ARCHIVE_NAME${NC}"
    fi

    if [ -f "$CURSOR_HANDOFF" ]; then
        rm "$CURSOR_HANDOFF"
        echo -e "${GREEN}✓ Removed $CURSOR_HANDOFF${NC}"
    fi
}

show_history() {
    ensure_dirs

    print_header "Handoff History"

    if [ -d "$ARCHIVE_DIR" ] && [ "$(ls -A $ARCHIVE_DIR 2>/dev/null)" ]; then
        ls -la "$ARCHIVE_DIR"/*.md 2>/dev/null | while read -r line; do
            echo "$line"
        done
    else
        echo -e "${YELLOW}No archived handoffs${NC}"
    fi
}

create_cursor_handoff() {
    local task="$1"
    local in_progress="$2"
    local next_steps="$3"

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    cat > "$CURSOR_HANDOFF" << EOF
# ACTIVE TASK HANDOFF

**Task**: $task
**Time**: $TIMESTAMP

## Current Status
$in_progress

## Next Steps
$(echo -e "$next_steps")

## Instructions for Cursor
Start your message with: "I'm resuming from a handoff. Let me read the context..."
Then reference this file and dev/handoff/HANDOFF.md for full details.
EOF

    echo -e "${GREEN}✓ Created $CURSOR_HANDOFF${NC}"
}

prepare_for_cursor() {
    print_header "Prepare for Cursor"

    if [ ! -f "$HANDOFF_FILE" ]; then
        echo -e "${YELLOW}No handoff file found. Creating quick handoff...${NC}"
        quick_handoff
        return
    fi

    # Extract key info and create cursor-friendly version
    TASK=$(grep "^\*\*Task\*\*:" "$HANDOFF_FILE" | sed 's/\*\*Task\*\*: //')

    cat > "$CURSOR_HANDOFF" << EOF
# ACTIVE TASK HANDOFF

$(cat "$HANDOFF_FILE")

---

## For Cursor
When starting in Cursor, begin with:
"I'm resuming work from a Claude Code handoff. Let me review the handoff document..."
EOF

    echo -e "${GREEN}✓ Cursor handoff ready at $CURSOR_HANDOFF${NC}"
    echo ""
    echo "In Cursor, start your conversation with:"
    echo -e "${CYAN}\"Resume from handoff - read .cursor-handoff and continue the task\"${NC}"
}

prepare_for_claude() {
    print_header "Prepare for Claude Code"

    if [ -f "$CURSOR_HANDOFF" ]; then
        # Append cursor session info to main handoff
        echo "" >> "$HANDOFF_FILE"
        echo "---" >> "$HANDOFF_FILE"
        echo "## Cursor Session Notes" >> "$HANDOFF_FILE"
        echo "*(Added $(date +"%Y-%m-%d %H:%M:%S"))*" >> "$HANDOFF_FILE"
        echo "" >> "$HANDOFF_FILE"
        cat "$CURSOR_HANDOFF" >> "$HANDOFF_FILE"

        echo -e "${GREEN}✓ Updated $HANDOFF_FILE with Cursor session${NC}"
    fi

    echo ""
    echo "In Claude Code, run:"
    echo -e "${CYAN}/resume${NC}"
}

# Main
case "${1:-help}" in
    new)
        create_handoff
        ;;
    quick)
        quick_handoff
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
    cursor)
        prepare_for_cursor
        ;;
    claude)
        prepare_for_claude
        ;;
    help|*)
        show_help
        ;;
esac
