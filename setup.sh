#!/bin/bash

# Claude Code Infrastructure Setup Script
# This script helps customize the .claude/ directory for your project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.claude}"

print_header "Claude Code Infrastructure Setup"

echo "This script will help you set up Claude Code for your project."
echo "Target directory: $TARGET_DIR"
echo ""

# Check if target already exists
if [ -d "$TARGET_DIR" ] && [ "$TARGET_DIR" != "." ]; then
    print_warning "Directory $TARGET_DIR already exists!"
    read -p "Do you want to continue and overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

# Step 1: Project Information
print_header "Step 1: Project Information"

read -p "Project name: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-"My Project"}

# Step 2: Frontend Stack
print_header "Step 2: Frontend Stack"

echo "Select your frontend framework:"
echo "  1) Next.js (React)"
echo "  2) React (Vite/CRA)"
echo "  3) Vue.js"
echo "  4) Angular"
echo "  5) Svelte"
echo "  6) None / Other"
read -p "Enter choice (1-6): " FE_CHOICE

case $FE_CHOICE in
    1) FRONTEND_FRAMEWORK="Next.js"; FRONTEND_KEYWORDS='"next.js", "react", "nextjs"' ;;
    2) FRONTEND_FRAMEWORK="React"; FRONTEND_KEYWORDS='"react", "vite"' ;;
    3) FRONTEND_FRAMEWORK="Vue.js"; FRONTEND_KEYWORDS='"vue", "vuejs", "vue.js"' ;;
    4) FRONTEND_FRAMEWORK="Angular"; FRONTEND_KEYWORDS='"angular", "ng"' ;;
    5) FRONTEND_FRAMEWORK="Svelte"; FRONTEND_KEYWORDS='"svelte", "sveltekit"' ;;
    *) FRONTEND_FRAMEWORK="Custom"; FRONTEND_KEYWORDS='"frontend"' ;;
esac

read -p "Frontend directory path (default: frontend): " FRONTEND_PATH
FRONTEND_PATH=${FRONTEND_PATH:-"frontend"}

echo "Select your package manager:"
echo "  1) pnpm"
echo "  2) npm"
echo "  3) yarn"
echo "  4) bun"
read -p "Enter choice (1-4): " PM_CHOICE

case $PM_CHOICE in
    1) PACKAGE_MANAGER="pnpm" ;;
    2) PACKAGE_MANAGER="npm" ;;
    3) PACKAGE_MANAGER="yarn" ;;
    4) PACKAGE_MANAGER="bun" ;;
    *) PACKAGE_MANAGER="npm" ;;
esac

FRONTEND_LINT_CMD="cd $FRONTEND_PATH && $PACKAGE_MANAGER lint"

# Step 3: Backend Stack
print_header "Step 3: Backend Stack"

echo "Select your backend framework:"
echo "  1) FastAPI (Python)"
echo "  2) Django (Python)"
echo "  3) Express (Node.js)"
echo "  4) NestJS (Node.js)"
echo "  5) Go (Gin/Echo)"
echo "  6) None / Other"
read -p "Enter choice (1-6): " BE_CHOICE

case $BE_CHOICE in
    1) BACKEND_FRAMEWORK="FastAPI"; BACKEND_LANG="Python"; BACKEND_KEYWORDS='"fastapi", "pydantic"'; BACKEND_EXT='"*.py"' ;;
    2) BACKEND_FRAMEWORK="Django"; BACKEND_LANG="Python"; BACKEND_KEYWORDS='"django"'; BACKEND_EXT='"*.py"' ;;
    3) BACKEND_FRAMEWORK="Express"; BACKEND_LANG="Node.js"; BACKEND_KEYWORDS='"express"'; BACKEND_EXT='"*.ts", "*.js"' ;;
    4) BACKEND_FRAMEWORK="NestJS"; BACKEND_LANG="Node.js"; BACKEND_KEYWORDS='"nestjs", "nest"'; BACKEND_EXT='"*.ts"' ;;
    5) BACKEND_FRAMEWORK="Go"; BACKEND_LANG="Go"; BACKEND_KEYWORDS='"gin", "echo", "go"'; BACKEND_EXT='"*.go"' ;;
    *) BACKEND_FRAMEWORK="Custom"; BACKEND_LANG="Custom"; BACKEND_KEYWORDS='"backend", "api"'; BACKEND_EXT='"*.py", "*.ts"' ;;
esac

read -p "Backend directory path (default: backend): " BACKEND_PATH
BACKEND_PATH=${BACKEND_PATH:-"backend"}

# Set lint command based on backend
case $BE_CHOICE in
    1|2) BACKEND_LINT_CMD="cd $BACKEND_PATH && python -m ruff check ." ;;
    3|4) BACKEND_LINT_CMD="cd $BACKEND_PATH && $PACKAGE_MANAGER lint" ;;
    5) BACKEND_LINT_CMD="cd $BACKEND_PATH && golangci-lint run" ;;
    *) BACKEND_LINT_CMD="echo 'No backend lint configured'" ;;
esac

# Step 4: Error Tracking
print_header "Step 4: Error Tracking"

echo "Select your error tracking solution:"
echo "  1) Sentry"
echo "  2) Datadog"
echo "  3) New Relic"
echo "  4) None / Other"
read -p "Enter choice (1-4): " ET_CHOICE

case $ET_CHOICE in
    1) ERROR_TRACKING="Sentry"; ET_KEYWORDS='"sentry", "capture_exception"' ;;
    2) ERROR_TRACKING="Datadog"; ET_KEYWORDS='"datadog", "dd-trace"' ;;
    3) ERROR_TRACKING="New Relic"; ET_KEYWORDS='"newrelic"' ;;
    *) ERROR_TRACKING="None"; ET_KEYWORDS='"error tracking", "monitoring"' ;;
esac

# Step 5: Confirmation
print_header "Configuration Summary"

echo "Project Name:      $PROJECT_NAME"
echo "Frontend:          $FRONTEND_FRAMEWORK ($FRONTEND_PATH)"
echo "Package Manager:   $PACKAGE_MANAGER"
echo "Backend:           $BACKEND_FRAMEWORK ($BACKEND_PATH)"
echo "Backend Language:  $BACKEND_LANG"
echo "Error Tracking:    $ERROR_TRACKING"
echo ""

read -p "Proceed with setup? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Step 6: Create Directory Structure
print_header "Setting Up Files"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/skills/frontend-dev-guidelines"
mkdir -p "$TARGET_DIR/skills/backend-dev-guidelines"
mkdir -p "$TARGET_DIR/skills/error-tracking"
mkdir -p "$TARGET_DIR/skills/skill-developer"
mkdir -p "$TARGET_DIR/hooks"
mkdir -p "$TARGET_DIR/commands"
mkdir -p "$TARGET_DIR/agents"

print_success "Created directory structure"

# Copy template files
if [ -f "$SCRIPT_DIR/settings.json" ]; then
    cp "$SCRIPT_DIR/settings.json" "$TARGET_DIR/"
    print_success "Copied settings.json"
fi

if [ -f "$SCRIPT_DIR/settings.local.json" ]; then
    cp "$SCRIPT_DIR/settings.local.json" "$TARGET_DIR/"
    print_success "Copied settings.local.json"
fi

# Copy hooks
if [ -d "$SCRIPT_DIR/hooks" ]; then
    cp "$SCRIPT_DIR/hooks/package.json" "$TARGET_DIR/hooks/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks/tsconfig.json" "$TARGET_DIR/hooks/" 2>/dev/null || true
    cp "$SCRIPT_DIR/hooks/skill-activation-prompt.ts" "$TARGET_DIR/hooks/" 2>/dev/null || true

    # Copy and customize build-checker
    if [ -f "$SCRIPT_DIR/hooks/build-checker.template.ts" ]; then
        sed -e "s|cd frontend|cd $FRONTEND_PATH|g" \
            -e "s|cd backend|cd $BACKEND_PATH|g" \
            -e "s|pnpm lint|$PACKAGE_MANAGER lint|g" \
            "$SCRIPT_DIR/hooks/build-checker.template.ts" > "$TARGET_DIR/hooks/build-checker.ts"
        print_success "Created hooks/build-checker.ts (customized)"
    fi

    if [ -f "$SCRIPT_DIR/hooks/error-handling-reminder.template.ts" ]; then
        cp "$SCRIPT_DIR/hooks/error-handling-reminder.template.ts" "$TARGET_DIR/hooks/error-handling-reminder.ts"
        print_success "Copied hooks/error-handling-reminder.ts"
    fi
fi

# Copy commands
if [ -d "$SCRIPT_DIR/commands" ]; then
    cp "$SCRIPT_DIR/commands/"*.md "$TARGET_DIR/commands/" 2>/dev/null || true
    print_success "Copied slash commands"
fi

# Copy skills
for skill_dir in "$SCRIPT_DIR/skills/"*/; do
    skill_name=$(basename "$skill_dir")
    if [ -d "$skill_dir" ] && [ "$skill_name" != "skill-rules.template.json" ]; then
        cp -r "$skill_dir" "$TARGET_DIR/skills/" 2>/dev/null || true
    fi
done
print_success "Copied skill templates"

# Create customized skill-rules.json
if [ -f "$SCRIPT_DIR/skills/skill-rules.template.json" ]; then
    sed -e "s|\[YOUR_PROJECT_NAME\]|$PROJECT_NAME|g" \
        -e "s|\[YOUR_BACKEND_FRAMEWORK\]|$BACKEND_FRAMEWORK|g" \
        -e "s|\[YOUR_FRONTEND_FRAMEWORK\]|$FRONTEND_FRAMEWORK|g" \
        -e "s|\"frontendPath\": \"frontend\"|\"frontendPath\": \"$FRONTEND_PATH\"|g" \
        -e "s|\"backendPath\": \"backend\"|\"backendPath\": \"$BACKEND_PATH\"|g" \
        -e "s|\"pnpm lint\"|\"$PACKAGE_MANAGER lint\"|g" \
        -e "s|\"_ADD_YOUR_FRAMEWORK_KEYWORDS_HERE_\"|$FRONTEND_KEYWORDS|g" \
        "$SCRIPT_DIR/skills/skill-rules.template.json" > "$TARGET_DIR/skills/skill-rules.json"
    print_success "Created skills/skill-rules.json (customized)"
fi

# Copy README and documentation
if [ -f "$SCRIPT_DIR/README.md" ]; then
    cp "$SCRIPT_DIR/README.md" "$TARGET_DIR/"
    print_success "Copied README.md"
fi

# Install hook dependencies
print_header "Installing Dependencies"

if [ -f "$TARGET_DIR/hooks/package.json" ]; then
    cd "$TARGET_DIR/hooks"
    if command -v npm &> /dev/null; then
        npm install --silent
        print_success "Installed hook dependencies"
    else
        print_warning "npm not found - run 'npm install' in $TARGET_DIR/hooks manually"
    fi
    cd - > /dev/null
fi

# Create dev/active directory for dev docs workflow
mkdir -p "dev/active"
print_success "Created dev/active/ directory for dev docs workflow"

# Final Summary
print_header "Setup Complete!"

echo "Your Claude Code infrastructure is ready at: $TARGET_DIR/"
echo ""
echo "Next Steps:"
echo "  1. Review and customize the skill files in $TARGET_DIR/skills/"
echo "  2. Copy CLAUDE.md.template to your project root and customize it"
echo "  3. (Optional) Copy cursorrules.template.md to .cursorrules for Cursor"
echo ""
echo "Test the setup:"
echo "  # Test skill activation"
echo "  echo '{\"cwd\": \".\", \"prompt\": \"create component\"}' | tsx $TARGET_DIR/hooks/skill-activation-prompt.ts"
echo ""
echo "Available Slash Commands:"
echo "  /dev-docs        - Create strategic development plans"
echo "  /dev-docs-update - Update docs before context compaction"
echo "  /code-review     - Perform architectural code review"
echo ""
print_success "Happy coding with Claude Code!"
