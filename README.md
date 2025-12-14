# Claude Code Infrastructure Template

A reusable, adaptable setup for Claude Code and Cursor AI that works across different projects and tech stacks.

## Quick Start

### Option 1: Auto-Analyze Codebase (Recommended)

```bash
# Analyze your codebase and generate customized skills
./.claude-template/analyze-codebase.sh /path/to/your/project .claude-generated

# Review the generated files
cat .claude-generated/skill-rules.json
cat .claude-generated/skills/*/SKILL.md

# Customize the TODO sections in generated files
# Then copy to your .claude/ directory
cp .claude-generated/skill-rules.json .claude/skills/
cp -r .claude-generated/skills/* .claude/skills/
cp .claude-generated/CLAUDE.md ./
```

The analyzer detects:
- **Frontend**: Framework (Next.js/React/Vue), UI library, state management, package manager
- **Backend**: Framework (FastAPI/Django/Express), language, database, task queue
- **Common imports**: Extracts actual import patterns from your codebase
- **Project structure**: Maps your directory layout

### Option 2: Interactive Setup
```bash
# 1. Copy template to your project
cp -r .claude-template /path/to/your/project/.claude-template
cd /path/to/your/project

# 2. Run interactive setup
./.claude-template/setup.sh

# 3. Copy CLAUDE.md template
cp .claude-template/CLAUDE.md.template CLAUDE.md
# Edit CLAUDE.md with your project details
```

### Option 2: Manual Setup
```bash
# 1. Copy the .claude directory
mkdir -p .claude
cp -r .claude-template/skills .claude/
cp -r .claude-template/hooks .claude/
cp -r .claude-template/commands .claude/
cp .claude-template/settings.json .claude/
cp .claude-template/settings.local.json .claude/

# 2. Install hook dependencies
cd .claude/hooks && npm install

# 3. Customize skill-rules.json for your project
# 4. Copy and customize CLAUDE.md.template to CLAUDE.md
```

### For Cursor Users
```bash
# Copy the Cursor rules template
cp .claude-template/cursorrules.template.md .cursorrules
# Edit .cursorrules with your project details
```

## Compatibility

| Platform | Feature Support | Notes |
|----------|----------------|-------|
| Claude Code CLI | ✅ Full | All features: hooks, skills, commands, agents |
| Cursor (Claude) | ✅ Full | CLAUDE.md + .cursorrules (no hooks) |
| VS Code Extension | ✅ Full | CLAUDE.md + skills |
| Other interfaces | ⚠️ Partial | CLAUDE.md only |

### Cursor-Specific Workarounds

Since Cursor doesn't run hooks, use these alternatives:

| Claude Code Feature | Cursor Alternative |
|--------------------|-------------------|
| Build checker hook | IDE "Lint on Save" / pre-commit hooks |
| Skill activation hook | Include key patterns in .cursorrules |
| Slash commands | Copy command content to chat |
| `/handoff` command | Run `./handoff.sh quick` then reference `.cursor-handoff` |
| `/resume` command | Read `dev/handoff/HANDOFF.md` at session start |

## Directory Structure

```
.claude-template/
├── README.md                    # This file
├── analyze-codebase.sh          # Auto-analyze and generate skills
├── setup.sh                     # Interactive setup script
├── CLAUDE.md.template           # Starter CLAUDE.md for projects
├── cursorrules.template.md      # Cursor-compatible rules template
├── settings.json                # Hook configuration
├── settings.local.json          # Local overrides (git-ignored)
│
├── skills/                      # Auto-activating guidelines
│   ├── skill-rules.template.json   # Activation triggers template
│   ├── frontend-dev-guidelines/    # Next.js/React patterns
│   │   └── SKILL.md
│   ├── backend-dev-guidelines/     # FastAPI/Express patterns
│   │   └── SKILL.md
│   ├── error-tracking/             # Sentry/monitoring patterns
│   │   └── SKILL.md
│   └── skill-developer/            # Meta-skill for creating skills
│       ├── SKILL.md
│       ├── TRIGGER_TYPES.md
│       ├── SKILL_RULES_REFERENCE.md
│       ├── HOOK_MECHANISMS.md
│       ├── TROUBLESHOOTING.md
│       ├── PATTERNS_LIBRARY.md
│       └── ADVANCED.md
│
├── hooks/                       # Automation scripts
│   ├── package.json
│   ├── tsconfig.json
│   ├── skill-activation-prompt.ts      # UserPromptSubmit hook
│   ├── build-checker.template.ts       # Stop hook (customize)
│   └── error-handling-reminder.template.ts
│
├── commands/                    # Slash commands
│   ├── dev-docs.md             # Create development plans
│   ├── dev-docs-update.md      # Update docs before compaction
│   ├── create-dev-docs.md      # Generate doc files
│   ├── code-review.md          # Architectural review
│   ├── handoff.md              # Generate handoff for tool transition
│   └── resume.md               # Resume from handoff document
│
├── handoff/                     # Tool transition management
│   ├── handoff.sh              # Shell script for handoffs
│   └── templates/              # Handoff document templates
│       ├── HANDOFF.template.md
│       └── cursor-handoff.template.md
│
├── agents/                      # Specialized agents (empty)
│
└── examples/                    # Complete configurations
    ├── nextjs-fastapi/         # Next.js 15 + FastAPI
    │   ├── skill-rules.json
    │   ├── CLAUDE.md
    │   └── .cursorrules
    ├── react-express/          # React + Express.js
    │   ├── skill-rules.json
    │   ├── CLAUDE.md
    │   └── .cursorrules
    └── vue-django/             # Vue 3 + Django
        ├── skill-rules.json
        ├── CLAUDE.md
        └── .cursorrules
```

## Template Files

### Core Templates

| File | Purpose | Action |
|------|---------|--------|
| `CLAUDE.md.template` | Project documentation for Claude | Copy to project root, customize |
| `cursorrules.template.md` | Cursor AI rules | Copy to `.cursorrules`, customize |
| `setup.sh` | Interactive setup wizard | Run to configure .claude/ |
| `skill-rules.template.json` | Skill activation config | Copy to `skill-rules.json`, customize |
| `build-checker.template.ts` | Lint/type check hook | Copy to `build-checker.ts`, customize |

### Pre-Built Examples

Use these as starting points for common tech stacks:

| Example | Frontend | Backend | Use Case |
|---------|----------|---------|----------|
| `nextjs-fastapi/` | Next.js 15, React 19, Tailwind | FastAPI, Python, Pydantic | Full-stack Python apps |
| `react-express/` | React 18, Vite, Tailwind | Express, Node.js, Prisma | JavaScript/TypeScript monorepo |
| `vue-django/` | Vue 3, Pinia, Tailwind | Django, DRF, Celery | Python Django apps |

## Feature Details

### Skills System

Skills are auto-activating guidelines that load based on triggers:

```json
{
  "backend-dev-guidelines": {
    "type": "domain",
    "enforcement": "suggest",
    "priority": "high",
    "promptTriggers": {
      "keywords": ["backend", "api", "endpoint"],
      "intentPatterns": ["(create|add).*?(route|endpoint)"]
    },
    "fileTriggers": {
      "pathPatterns": ["backend/**/*.py"],
      "contentPatterns": ["from fastapi"]
    }
  }
}
```

**Trigger Types:**
- **Keywords**: Exact substring matches in prompts
- **Intent Patterns**: Regex for action detection
- **File Paths**: Glob patterns for edited files
- **Content Patterns**: Regex in file content

**Enforcement Levels:**
- `suggest` - Advisory recommendation
- `warn` - Warning with proceed option
- `block` - Requires skill activation first

### Hooks System

| Hook | Trigger | Use Case |
|------|---------|----------|
| `userPromptSubmit` | Before Claude processes | Skill suggestions |
| `stop` | After Claude responds | Linting, reminders |
| `preToolUse` | Before tool execution | Validation |
| `postToolUse` | After tool execution | Logging |

### Commands System

Slash commands expand into full prompts:

- `/dev-docs` - Create strategic development plans
- `/dev-docs-update` - Update docs before context compaction
- `/code-review` - Perform architectural code review
- `/create-dev-docs` - Generate doc files from plans
- `/handoff` - Generate handoff document for tool transition
- `/resume` - Resume work from a handoff document

### Handoff System

Seamlessly transition between Claude Code and Cursor when hitting rate limits or switching contexts.

**The Problem**: When you hit Claude Code rate limits mid-task, you lose context switching to Cursor. Similarly, resuming in Claude Code after working in Cursor requires re-explaining everything.

**The Solution**: Handoff documents capture your current state, enabling seamless continuation.

#### Workflow

```
┌─────────────────┐     /handoff      ┌─────────────────┐
│  Claude Code    │ ──────────────►  │  Cursor         │
│  (hit limit)    │                   │  (continue)     │
└─────────────────┘                   └─────────────────┘
        ▲                                     │
        │           ./handoff.sh              │
        └─────────────────────────────────────┘
               /resume
```

#### Using Handoffs

**From Claude Code (when hitting rate limit):**
```
/handoff
```
This creates:
- `dev/handoff/HANDOFF.md` - Full context document
- `.cursor-handoff` - Condensed version for Cursor

**In Cursor (to continue):**
```
Resume from handoff - read .cursor-handoff and continue the task
```

**Back to Claude Code:**
```
/resume
```

**Using Shell Script (works anywhere):**
```bash
# Quick handoff with minimal prompts
./.claude-template/handoff/handoff.sh quick

# Full interactive handoff
./.claude-template/handoff/handoff.sh new

# Check current handoff status
./.claude-template/handoff/handoff.sh status

# Archive old handoff and start fresh
./.claude-template/handoff/handoff.sh archive

# Prepare specifically for Cursor
./.claude-template/handoff/handoff.sh cursor

# Prepare for Claude Code resume
./.claude-template/handoff/handoff.sh claude
```

#### Handoff Document Contents

The handoff captures:
- **Current Goal**: What you're trying to accomplish
- **Completed Work**: What's done in this session
- **In Progress**: What's partially complete
- **Next Steps**: Specific actions to take
- **Key Files**: Files modified with descriptions
- **Context & Gotchas**: Important considerations
- **Resume Instructions**: How to continue

## Customization Guide

### Step 1: Run Setup Script

```bash
./setup.sh
```

The script prompts for:
- Project name
- Frontend framework (Next.js, React, Vue, Angular, etc.)
- Backend framework (FastAPI, Express, Django, etc.)
- Package manager (pnpm, npm, yarn)
- Error tracking solution (Sentry, Datadog, etc.)

### Step 2: Customize CLAUDE.md

Copy and edit the template:

```bash
cp .claude-template/CLAUDE.md.template CLAUDE.md
```

Add your project-specific:
- Architecture overview
- Setup commands
- Environment variables
- Project quirks and gotchas

### Step 3: Customize Skills (Optional)

Edit `skills/*/SKILL.md` files to add:
- Project-specific patterns
- Custom code examples
- Framework-specific guidelines

### Step 4: For Cursor Users

```bash
cp .claude-template/cursorrules.template.md .cursorrules
```

Include condensed patterns from skills since Cursor can't run the Skill tool.

## Testing Your Setup

### Test Skill Activation
```bash
echo '{"cwd": ".", "prompt": "create a new component"}' | \
  npx tsx .claude/hooks/skill-activation-prompt.ts
```

### Test Build Checker
```bash
echo '{"cwd": ".", "tool_uses": [{"tool": "Edit", "parameters": {"file_path": "frontend/src/test.tsx"}}]}' | \
  npx tsx .claude/hooks/build-checker.ts
```

### Validate JSON Configuration
```bash
cat .claude/skills/skill-rules.json | jq .
```

## Troubleshooting

### Skills Not Activating
1. Check `skill-rules.json` syntax: `jq . skill-rules.json`
2. Verify keywords match your prompts (case-insensitive)
3. Test intent patterns at regex101.com
4. Run hook manually to see output

### Hooks Not Running
1. Install dependencies: `cd .claude/hooks && npm install`
2. Check `settings.json` has correct paths
3. Verify Node.js 20+ is available
4. Check tsx is installed: `npx tsx --version`

### Cursor Not Reading Rules
1. Ensure `.cursorrules` is in project root
2. File must not be empty
3. Check file permissions
4. Restart Cursor after changes

## Migration from Existing Setup

```bash
# 1. Backup existing setup
mv .claude .claude-backup

# 2. Copy template
cp -r .claude-template/.claude .

# 3. Migrate customizations
cp .claude-backup/skills/*/SKILL.md .claude/skills/*/
# Update skill-rules.json with your patterns

# 4. Test
echo '{"cwd": ".", "prompt": "test"}' | npx tsx .claude/hooks/skill-activation-prompt.ts
```

## Contributing

1. Make changes in `.claude-template/`
2. Test with the example configurations
3. Update this README
4. Submit PR

---

**Version**: 2.2.0 (Reusable Template + Handoff System)
**Compatible With**: Claude Code, Cursor (Claude models), VS Code Claude Extension
