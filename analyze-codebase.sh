#!/bin/bash

# Codebase Analyzer for Claude Code Skills
# Analyzes your project and generates customized skill configurations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() { echo -e "${CYAN}ℹ $1${NC}"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Default to current directory
PROJECT_ROOT="${1:-.}"
OUTPUT_DIR="${2:-.claude-generated}"

print_header "Codebase Analyzer for Claude Code Skills"
echo "Analyzing: $PROJECT_ROOT"
echo "Output: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# ============================================
# DETECTION FUNCTIONS
# ============================================

detect_frontend() {
    local frontend_path=""
    local framework=""
    local package_manager=""
    local ui_library=""
    local state_management=""
    local keywords=()

    # Find frontend directory
    for dir in "frontend" "client" "web" "app" "src"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            if [ -f "$PROJECT_ROOT/$dir/package.json" ] || [ -f "$PROJECT_ROOT/$dir/next.config.js" ] || [ -f "$PROJECT_ROOT/$dir/vite.config.ts" ]; then
                frontend_path="$dir"
                break
            fi
        fi
    done

    # Check root level for monorepo
    if [ -z "$frontend_path" ] && [ -f "$PROJECT_ROOT/package.json" ]; then
        if grep -q "next\|react\|vue\|angular" "$PROJECT_ROOT/package.json" 2>/dev/null; then
            frontend_path="."
        fi
    fi

    if [ -z "$frontend_path" ]; then
        echo "none"
        return
    fi

    local pkg_file="$PROJECT_ROOT/$frontend_path/package.json"

    # Detect package manager
    if [ -f "$PROJECT_ROOT/$frontend_path/pnpm-lock.yaml" ]; then
        package_manager="pnpm"
    elif [ -f "$PROJECT_ROOT/$frontend_path/yarn.lock" ]; then
        package_manager="yarn"
    elif [ -f "$PROJECT_ROOT/$frontend_path/bun.lockb" ]; then
        package_manager="bun"
    else
        package_manager="npm"
    fi

    # Detect framework
    if [ -f "$pkg_file" ]; then
        if grep -q '"next"' "$pkg_file"; then
            framework="nextjs"
            keywords+=("next.js" "nextjs" "app router" "server component" "client component")
        elif grep -q '"nuxt"' "$pkg_file"; then
            framework="nuxt"
            keywords+=("nuxt" "nuxtjs" "vue")
        elif grep -q '"vue"' "$pkg_file"; then
            framework="vue"
            keywords+=("vue" "vuejs" "composition api" "pinia")
        elif grep -q '"@angular/core"' "$pkg_file"; then
            framework="angular"
            keywords+=("angular" "ng" "rxjs")
        elif grep -q '"svelte"' "$pkg_file"; then
            framework="svelte"
            keywords+=("svelte" "sveltekit")
        elif grep -q '"react"' "$pkg_file"; then
            framework="react"
            keywords+=("react" "jsx" "tsx")
        fi

        # Detect UI library
        if grep -q '"@radix-ui\|"shadcn\|"@shadcn"' "$pkg_file"; then
            ui_library="shadcn"
            keywords+=("shadcn" "radix")
        elif grep -q '"@mui/material\|"@material-ui"' "$pkg_file"; then
            ui_library="mui"
            keywords+=("mui" "material-ui")
        elif grep -q '"antd"' "$pkg_file"; then
            ui_library="antd"
            keywords+=("antd" "ant design")
        elif grep -q '"@chakra-ui"' "$pkg_file"; then
            ui_library="chakra"
            keywords+=("chakra")
        fi

        # Detect state management
        if grep -q '"@tanstack/react-query\|"react-query"' "$pkg_file"; then
            state_management="tanstack-query"
            keywords+=("tanstack" "react-query" "useQuery")
        fi
        if grep -q '"zustand"' "$pkg_file"; then
            state_management="${state_management:+$state_management+}zustand"
            keywords+=("zustand")
        elif grep -q '"redux\|"@reduxjs"' "$pkg_file"; then
            state_management="${state_management:+$state_management+}redux"
            keywords+=("redux")
        elif grep -q '"pinia"' "$pkg_file"; then
            state_management="${state_management:+$state_management+}pinia"
            keywords+=("pinia")
        fi

        # Detect styling
        if grep -q '"tailwindcss"' "$pkg_file" || [ -f "$PROJECT_ROOT/$frontend_path/tailwind.config.js" ] || [ -f "$PROJECT_ROOT/$frontend_path/tailwind.config.ts" ]; then
            keywords+=("tailwind" "tailwindcss")
        fi
    fi

    # Add common keywords
    keywords+=("component" "page" "ui" "interface" "modal" "dialog" "form" "styling" "frontend")

    echo "$frontend_path|$framework|$package_manager|$ui_library|$state_management|${keywords[*]}"
}

detect_backend() {
    local backend_path=""
    local framework=""
    local language=""
    local database=""
    local keywords=()
    local imports=()

    # Find backend directory
    for dir in "backend" "server" "api" "src/server" "src/api"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            backend_path="$dir"
            break
        fi
    done

    if [ -z "$backend_path" ]; then
        # Check for backend files in root
        if [ -f "$PROJECT_ROOT/main.py" ] || [ -f "$PROJECT_ROOT/app.py" ] || [ -f "$PROJECT_ROOT/manage.py" ]; then
            backend_path="."
        elif [ -f "$PROJECT_ROOT/server.ts" ] || [ -f "$PROJECT_ROOT/server.js" ] || [ -f "$PROJECT_ROOT/index.ts" ]; then
            backend_path="."
        fi
    fi

    if [ -z "$backend_path" ]; then
        echo "none"
        return
    fi

    # Detect Python frameworks
    if [ -f "$PROJECT_ROOT/$backend_path/requirements.txt" ] || [ -f "$PROJECT_ROOT/$backend_path/pyproject.toml" ] || find "$PROJECT_ROOT/$backend_path" -name "*.py" -type f 2>/dev/null | head -1 | grep -q .; then
        language="python"

        local req_file=""
        [ -f "$PROJECT_ROOT/$backend_path/requirements.txt" ] && req_file="$PROJECT_ROOT/$backend_path/requirements.txt"
        [ -f "$PROJECT_ROOT/requirements.txt" ] && req_file="$PROJECT_ROOT/requirements.txt"

        if [ -n "$req_file" ]; then
            if grep -qi "fastapi" "$req_file"; then
                framework="fastapi"
                keywords+=("fastapi" "pydantic" "async" "await" "router" "endpoint")
                imports+=("from fastapi" "@router\\\\." "class.*\\\\(BaseModel\\\\)")
            elif grep -qi "django" "$req_file"; then
                framework="django"
                keywords+=("django" "drf" "django rest framework" "viewset" "serializer" "model")
                imports+=("from django" "from rest_framework")
            elif grep -qi "flask" "$req_file"; then
                framework="flask"
                keywords+=("flask" "blueprint" "route")
                imports+=("from flask")
            fi

            # Detect database
            if grep -qi "sqlalchemy" "$req_file"; then
                database="sqlalchemy"
                keywords+=("sqlalchemy" "orm" "query")
            fi
            if grep -qi "prisma" "$req_file"; then
                database="prisma"
                keywords+=("prisma")
            fi
            if grep -qi "azure-cosmos\|cosmos" "$req_file"; then
                database="${database:+$database+}cosmos"
                keywords+=("cosmos" "cosmosdb" "azure")
                imports+=("CosmosClient" "from azure")
            fi
            if grep -qi "pymongo\|motor" "$req_file"; then
                database="${database:+$database+}mongodb"
                keywords+=("mongodb" "mongo")
            fi

            # Detect task queue
            if grep -qi "celery" "$req_file"; then
                keywords+=("celery" "task" "worker" "queue")
                imports+=("@celery_app\\\\.task" "from celery")
            fi

            # Detect monitoring
            if grep -qi "sentry" "$req_file"; then
                keywords+=("sentry" "error tracking")
                imports+=("sentry_sdk" "capture_exception")
            fi
        fi
    fi

    # Detect Node.js frameworks
    if [ -f "$PROJECT_ROOT/$backend_path/package.json" ]; then
        language="nodejs"
        local pkg_file="$PROJECT_ROOT/$backend_path/package.json"

        if grep -q '"express"' "$pkg_file"; then
            framework="express"
            keywords+=("express" "router" "middleware" "controller")
            imports+=("import.*express" "require.*express" "router\\\\.")
        elif grep -q '"@nestjs/core"' "$pkg_file"; then
            framework="nestjs"
            keywords+=("nestjs" "nest" "controller" "service" "module")
            imports+=("@nestjs" "@Controller" "@Injectable")
        elif grep -q '"fastify"' "$pkg_file"; then
            framework="fastify"
            keywords+=("fastify" "route" "handler")
        elif grep -q '"hono"' "$pkg_file"; then
            framework="hono"
            keywords+=("hono" "route")
        fi

        # Detect database
        if grep -q '"prisma\|"@prisma"' "$pkg_file"; then
            database="prisma"
            keywords+=("prisma" "orm")
            imports+=("PrismaClient" "prisma\\\\.")
        fi
        if grep -q '"mongoose"' "$pkg_file"; then
            database="${database:+$database+}mongodb"
            keywords+=("mongodb" "mongoose")
        fi
        if grep -q '"typeorm"' "$pkg_file"; then
            database="${database:+$database+}typeorm"
            keywords+=("typeorm")
        fi
    fi

    # Add common keywords
    keywords+=("backend" "api" "route" "endpoint" "schema" "database" "error handling" "validation" "middleware")

    echo "$backend_path|$framework|$language|$database|${keywords[*]}|${imports[*]}"
}

detect_project_structure() {
    local dirs=()

    # Find key directories
    for dir in $(find "$PROJECT_ROOT" -maxdepth 2 -type d -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/.venv/*" -not -path "*/__pycache__/*" 2>/dev/null); do
        local name=$(basename "$dir")
        case "$name" in
            routers|routes|controllers|handlers) dirs+=("routers:$dir") ;;
            services|service) dirs+=("services:$dir") ;;
            models|entities) dirs+=("models:$dir") ;;
            schemas|dto|dtos) dirs+=("schemas:$dir") ;;
            components|ui) dirs+=("components:$dir") ;;
            hooks|composables) dirs+=("hooks:$dir") ;;
            lib|utils|helpers) dirs+=("utils:$dir") ;;
            tests|__tests__|test) dirs+=("tests:$dir") ;;
        esac
    done

    echo "${dirs[*]}"
}

extract_imports() {
    local dir="$1"
    local ext="$2"
    local limit="${3:-20}"

    find "$dir" -name "*.$ext" -type f -not -path "*/node_modules/*" -not -path "*/.venv/*" 2>/dev/null | \
        head -50 | \
        xargs grep -h "^import\|^from" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -"$limit" | \
        awk '{$1=""; print $0}' | sed 's/^ //'
}

# ============================================
# MAIN ANALYSIS
# ============================================

print_header "Analyzing Codebase..."

# Detect frontend
print_info "Detecting frontend..."
FRONTEND_INFO=$(detect_frontend)
if [ "$FRONTEND_INFO" != "none" ]; then
    IFS='|' read -r FE_PATH FE_FRAMEWORK FE_PKG_MGR FE_UI FE_STATE FE_KEYWORDS <<< "$FRONTEND_INFO"
    print_success "Frontend: $FE_FRAMEWORK in $FE_PATH (using $FE_PKG_MGR)"
    [ -n "$FE_UI" ] && print_info "  UI Library: $FE_UI"
    [ -n "$FE_STATE" ] && print_info "  State: $FE_STATE"
else
    print_warning "No frontend detected"
fi

# Detect backend
print_info "Detecting backend..."
BACKEND_INFO=$(detect_backend)
if [ "$BACKEND_INFO" != "none" ]; then
    IFS='|' read -r BE_PATH BE_FRAMEWORK BE_LANG BE_DB BE_KEYWORDS BE_IMPORTS <<< "$BACKEND_INFO"
    print_success "Backend: $BE_FRAMEWORK ($BE_LANG) in $BE_PATH"
    [ -n "$BE_DB" ] && print_info "  Database: $BE_DB"
else
    print_warning "No backend detected"
fi

# Detect structure
print_info "Detecting project structure..."
STRUCTURE=$(detect_project_structure)
for item in $STRUCTURE; do
    IFS=':' read -r type path <<< "$item"
    print_info "  Found $type: $path"
done

# ============================================
# GENERATE SKILL-RULES.JSON
# ============================================

print_header "Generating skill-rules.json..."

# Get project name from directory
PROJECT_NAME=$(basename "$(cd "$PROJECT_ROOT" && pwd)")

cat > "$OUTPUT_DIR/skill-rules.json" << EOF
{
    "version": "1.0",
    "description": "Auto-generated skill activation triggers for $PROJECT_NAME",
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "projectConfig": {
        "frontendPath": "${FE_PATH:-frontend}",
        "backendPath": "${BE_PATH:-backend}",
        "frontendLintCommand": "${FE_PKG_MGR:-npm} lint",
        "backendLintCommand": "$([ "$BE_LANG" = "python" ] && echo "ruff check ." || echo "npm run lint")"
    },
    "skills": {
EOF

# Generate backend skill
if [ "$BACKEND_INFO" != "none" ]; then
    # Build keywords JSON array
    BE_KW_JSON=$(echo "$BE_KEYWORDS" | tr ' ' '\n' | sort -u | awk '{print "            \""$0"\""}' | paste -sd ',' - | sed 's/,/, /g')

    # Build imports JSON array
    BE_IMP_JSON=$(echo "$BE_IMPORTS" | tr ' ' '\n' | sort -u | grep -v '^$' | awk '{print "            \""$0"\""}' | paste -sd ',' - | sed 's/,/, /g')

    cat >> "$OUTPUT_DIR/skill-rules.json" << EOF
        "backend-dev-guidelines": {
            "type": "domain",
            "enforcement": "suggest",
            "priority": "high",
            "description": "Backend development patterns for $BE_FRAMEWORK ($BE_LANG)${BE_DB:+ with $BE_DB}",
            "promptTriggers": {
                "keywords": [
$BE_KW_JSON
                ],
                "intentPatterns": [
                    "(create|add|implement|build).*?(route|endpoint|API|service|schema)",
                    "(fix|handle|debug).*?(error|exception|backend)",
                    "(how to|best practice).*?(backend|api|$BE_FRAMEWORK)"
                ]
            },
            "fileTriggers": {
                "pathPatterns": [
                    "${BE_PATH}/**/*.$([ "$BE_LANG" = "python" ] && echo "py" || echo "ts")"
                ],
                "pathExclusions": [
                    "**/*test*.$([ "$BE_LANG" = "python" ] && echo "py" || echo "ts")",
                    "**/node_modules/**",
                    "**/__pycache__/**"
                ]$([ -n "$BE_IMP_JSON" ] && echo ",
                \"contentPatterns\": [
$BE_IMP_JSON
                ]")
            }
        }$([ "$FRONTEND_INFO" != "none" ] && echo ",")
EOF
fi

# Generate frontend skill
if [ "$FRONTEND_INFO" != "none" ]; then
    FE_KW_JSON=$(echo "$FE_KEYWORDS" | tr ' ' '\n' | sort -u | awk '{print "            \""$0"\""}' | paste -sd ',' - | sed 's/,/, /g')

    cat >> "$OUTPUT_DIR/skill-rules.json" << EOF
        "frontend-dev-guidelines": {
            "type": "domain",
            "enforcement": "suggest",
            "priority": "high",
            "description": "Frontend development patterns for $FE_FRAMEWORK${FE_UI:+ with $FE_UI}${FE_STATE:+ and $FE_STATE}",
            "promptTriggers": {
                "keywords": [
$FE_KW_JSON
                ],
                "intentPatterns": [
                    "(create|add|make|build|update).*?(component|UI|page|modal|form)",
                    "(how to|best practice).*?(component|$FE_FRAMEWORK|frontend)",
                    "(style|design|layout).*?(component|UI)"
                ]
            },
            "fileTriggers": {
                "pathPatterns": [
                    "${FE_PATH}/**/*.tsx",
                    "${FE_PATH}/**/*.ts",
                    "${FE_PATH}/**/*.vue"
                ],
                "pathExclusions": [
                    "**/*.test.*",
                    "**/*.spec.*",
                    "**/node_modules/**"
                ]
            },
            "skipConditions": {
                "sessionSkillUsed": true,
                "fileMarkers": ["@skip-validation"]
            }
        }
EOF
fi

cat >> "$OUTPUT_DIR/skill-rules.json" << EOF
    }
}
EOF

print_success "Generated $OUTPUT_DIR/skill-rules.json"

# ============================================
# GENERATE BACKEND SKILL.MD
# ============================================

if [ "$BACKEND_INFO" != "none" ]; then
    print_info "Generating backend skill..."
    mkdir -p "$OUTPUT_DIR/skills/backend-dev-guidelines"

    # Extract common imports
    COMMON_IMPORTS=""
    if [ "$BE_LANG" = "python" ]; then
        COMMON_IMPORTS=$(extract_imports "$PROJECT_ROOT/$BE_PATH" "py" 15)
    else
        COMMON_IMPORTS=$(extract_imports "$PROJECT_ROOT/$BE_PATH" "ts" 15)
    fi

    # Capitalize first letter (portable)
    BE_FRAMEWORK_CAP=$(echo "$BE_FRAMEWORK" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    BE_LANG_CAP=$(echo "$BE_LANG" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    BE_DB_DISPLAY="${BE_DB:-Not detected}"

    cat > "$OUTPUT_DIR/skills/backend-dev-guidelines/SKILL.md" << SKILL_EOF
---
name: backend-dev-guidelines
description: Backend development patterns for $PROJECT_NAME using $BE_FRAMEWORK ($BE_LANG)${BE_DB:+ with $BE_DB}
---

# Backend Development Guidelines

> **Auto-generated** - Review and customize for your project

## Tech Stack (Detected)

- **Framework**: $BE_FRAMEWORK_CAP
- **Language**: $BE_LANG_CAP
- **Database**: $BE_DB_DISPLAY
- **Path**: \`$BE_PATH/\`

## Project Structure

\`\`\`
$BE_PATH/
SKILL_EOF

    # Add detected structure
    for item in $STRUCTURE; do
        IFS=':' read -r type path <<< "$item"
        rel_path="${path#$PROJECT_ROOT/}"
        if [[ "$rel_path" == "$BE_PATH"* ]]; then
            echo "├── ${rel_path#$BE_PATH/}/" >> "$OUTPUT_DIR/skills/backend-dev-guidelines/SKILL.md"
        fi
    done

    CODE_LANG=$([ "$BE_LANG" = "python" ] && echo "python" || echo "typescript")
    cat >> "$OUTPUT_DIR/skills/backend-dev-guidelines/SKILL.md" << SKILL_EOF2
\`\`\`

## Common Imports (Detected)

\`\`\`$CODE_LANG
$COMMON_IMPORTS
\`\`\`

## Patterns

### TODO: Add Your Patterns

1. **Router/Endpoint Pattern**: [Add your typical route structure]
2. **Service Layer Pattern**: [Add your service class structure]
3. **Error Handling Pattern**: [Add your error handling approach]
4. **Validation Pattern**: [Add your validation approach]

## Project Quirks

> **TODO**: Add project-specific gotchas discovered during development

1. [Add quirk 1]
2. [Add quirk 2]

---

**Review this file and add your project-specific patterns!**
SKILL_EOF2

    print_success "Generated $OUTPUT_DIR/skills/backend-dev-guidelines/SKILL.md"
fi

# ============================================
# GENERATE FRONTEND SKILL.MD
# ============================================

if [ "$FRONTEND_INFO" != "none" ]; then
    print_info "Generating frontend skill..."
    mkdir -p "$OUTPUT_DIR/skills/frontend-dev-guidelines"

    COMMON_IMPORTS=$(extract_imports "$PROJECT_ROOT/$FE_PATH" "tsx" 15)
    [ -z "$COMMON_IMPORTS" ] && COMMON_IMPORTS=$(extract_imports "$PROJECT_ROOT/$FE_PATH" "ts" 15)

    FE_FRAMEWORK_CAP=$(echo "$FE_FRAMEWORK" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    FE_UI_DISPLAY="${FE_UI:-Not detected}"
    FE_STATE_DISPLAY="${FE_STATE:-Not detected}"

    cat > "$OUTPUT_DIR/skills/frontend-dev-guidelines/SKILL.md" << FE_SKILL_EOF
---
name: frontend-dev-guidelines
description: Frontend development patterns for $PROJECT_NAME using $FE_FRAMEWORK${FE_UI:+ with $FE_UI}
---

# Frontend Development Guidelines

> **Auto-generated** - Review and customize for your project

## Tech Stack (Detected)

- **Framework**: $FE_FRAMEWORK_CAP
- **UI Library**: $FE_UI_DISPLAY
- **State Management**: $FE_STATE_DISPLAY
- **Package Manager**: $FE_PKG_MGR
- **Path**: \`$FE_PATH/\`

## Project Structure

\`\`\`
$FE_PATH/
FE_SKILL_EOF

    for item in $STRUCTURE; do
        IFS=':' read -r type path <<< "$item"
        rel_path="${path#$PROJECT_ROOT/}"
        if [[ "$rel_path" == "$FE_PATH"* ]]; then
            echo "├── ${rel_path#$FE_PATH/}/" >> "$OUTPUT_DIR/skills/frontend-dev-guidelines/SKILL.md"
        fi
    done

    USE_CLIENT_LINE=""
    [ "$FE_FRAMEWORK" = "nextjs" ] && USE_CLIENT_LINE="'use client'; // Only if using hooks/state/browser APIs
"
    cat >> "$OUTPUT_DIR/skills/frontend-dev-guidelines/SKILL.md" << FE_SKILL_EOF2
\`\`\`

## Common Imports (Detected)

\`\`\`typescript
$COMMON_IMPORTS
\`\`\`

## Component Pattern

\`\`\`typescript
$USE_CLIENT_LINE// TODO: Add your typical component structure
interface Props {
  // Props
}

export function ComponentName({ }: Props) {
  // 1. Hooks
  // 2. Handlers
  // 3. Return JSX
  return <div>...</div>;
}
\`\`\`

## Patterns

### TODO: Add Your Patterns

1. **Data Fetching Pattern**: [Add your typical data fetching approach]
2. **Form Pattern**: [Add your form handling approach]
3. **Styling Pattern**: [Add your styling conventions]
4. **Error Handling Pattern**: [Add your error boundary/handling approach]

## Project Quirks

> **TODO**: Add project-specific gotchas discovered during development

1. [Add quirk 1]
2. [Add quirk 2]

---

**Review this file and add your project-specific patterns!**
FE_SKILL_EOF2

    print_success "Generated $OUTPUT_DIR/skills/frontend-dev-guidelines/SKILL.md"
fi

# ============================================
# GENERATE CLAUDE.MD
# ============================================

print_info "Generating CLAUDE.md..."

# Build CLAUDE.md content
CURRENT_DATE=$(date +"%Y-%m-%d")

cat > "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_EOF1
# CLAUDE.md

**Auto-generated** - Last Updated: $CURRENT_DATE

> Review and customize this file for your project!

## Tech Stack (Detected)

CLAUDE_EOF1

if [ "$FRONTEND_INFO" != "none" ]; then
    FE_UI_DISPLAY="${FE_UI:-TBD}"
    FE_STATE_DISPLAY="${FE_STATE:-TBD}"
    cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_FE_EOF
### Frontend
- **Framework**: $FE_FRAMEWORK_CAP
- **UI Library**: $FE_UI_DISPLAY
- **State**: $FE_STATE_DISPLAY
- **Package Manager**: $FE_PKG_MGR
- **Path**: \`$FE_PATH/\`

CLAUDE_FE_EOF
fi

if [ "$BACKEND_INFO" != "none" ]; then
    BE_DB_DISPLAY="${BE_DB:-TBD}"
    cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_BE_EOF
### Backend
- **Framework**: $BE_FRAMEWORK_CAP
- **Language**: $BE_LANG_CAP
- **Database**: $BE_DB_DISPLAY
- **Path**: \`$BE_PATH/\`

CLAUDE_BE_EOF
fi

cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_QS_EOF
## Quick Start

\`\`\`bash
CLAUDE_QS_EOF

if [ "$FRONTEND_INFO" != "none" ]; then
    cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_FE_QS_EOF
# Frontend
cd $FE_PATH
$FE_PKG_MGR install
$FE_PKG_MGR dev

CLAUDE_FE_QS_EOF
fi

if [ "$BACKEND_INFO" != "none" ]; then
    echo "# Backend" >> "$OUTPUT_DIR/CLAUDE.md"
    echo "cd $BE_PATH" >> "$OUTPUT_DIR/CLAUDE.md"
    if [ "$BE_LANG" = "python" ]; then
        echo "python -m venv .venv" >> "$OUTPUT_DIR/CLAUDE.md"
        echo "source .venv/bin/activate" >> "$OUTPUT_DIR/CLAUDE.md"
        echo "pip install -r requirements.txt" >> "$OUTPUT_DIR/CLAUDE.md"
        if [ "$BE_FRAMEWORK" = "fastapi" ]; then
            echo "uvicorn main:app --reload" >> "$OUTPUT_DIR/CLAUDE.md"
        else
            echo "python manage.py runserver" >> "$OUTPUT_DIR/CLAUDE.md"
        fi
    else
        echo "npm install" >> "$OUTPUT_DIR/CLAUDE.md"
        echo "npm run dev" >> "$OUTPUT_DIR/CLAUDE.md"
    fi
fi

cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_CMD_EOF
\`\`\`

## Common Commands

\`\`\`bash
# Linting
CLAUDE_CMD_EOF

[ "$FRONTEND_INFO" != "none" ] && echo "cd $FE_PATH && $FE_PKG_MGR lint" >> "$OUTPUT_DIR/CLAUDE.md"
[ "$BACKEND_INFO" != "none" ] && [ "$BE_LANG" = "python" ] && echo "cd $BE_PATH && ruff check . && mypy ." >> "$OUTPUT_DIR/CLAUDE.md"
[ "$BACKEND_INFO" != "none" ] && [ "$BE_LANG" = "nodejs" ] && echo "cd $BE_PATH && npm run lint" >> "$OUTPUT_DIR/CLAUDE.md"

echo "" >> "$OUTPUT_DIR/CLAUDE.md"
echo "# Tests" >> "$OUTPUT_DIR/CLAUDE.md"

[ "$FRONTEND_INFO" != "none" ] && echo "cd $FE_PATH && $FE_PKG_MGR test" >> "$OUTPUT_DIR/CLAUDE.md"
[ "$BACKEND_INFO" != "none" ] && [ "$BE_LANG" = "python" ] && echo "cd $BE_PATH && pytest" >> "$OUTPUT_DIR/CLAUDE.md"
[ "$BACKEND_INFO" != "none" ] && [ "$BE_LANG" = "nodejs" ] && echo "cd $BE_PATH && npm test" >> "$OUTPUT_DIR/CLAUDE.md"

cat >> "$OUTPUT_DIR/CLAUDE.md" << CLAUDE_QUIRKS_EOF
\`\`\`

## Project Quirks & Gotchas

> **TODO**: Add project-specific gotchas as you discover them

### Example Format:
#### 1. **[Quirk Title]**
\`\`\`
# Bad
[bad code example]

# Good
[good code example]
\`\`\`
**Why**: [Explanation]

---

**Review and customize this file!**
CLAUDE_QUIRKS_EOF

print_success "Generated $OUTPUT_DIR/CLAUDE.md"

# ============================================
# SUMMARY
# ============================================

print_header "Analysis Complete!"

echo "Generated files in $OUTPUT_DIR/:"
echo ""
find "$OUTPUT_DIR" -type f | sed "s|$OUTPUT_DIR/|  |"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review generated files in $OUTPUT_DIR/"
echo "2. Add your project-specific patterns to SKILL.md files"
echo "3. Add project quirks to CLAUDE.md"
echo "4. Copy to .claude/ when ready:"
echo ""
echo -e "   ${CYAN}cp $OUTPUT_DIR/skill-rules.json .claude/skills/${NC}"
echo -e "   ${CYAN}cp -r $OUTPUT_DIR/skills/* .claude/skills/${NC}"
echo -e "   ${CYAN}cp $OUTPUT_DIR/CLAUDE.md ./${NC}"
echo ""
print_success "Done! Review and customize the generated files."
