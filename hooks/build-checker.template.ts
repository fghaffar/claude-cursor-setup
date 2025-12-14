#!/usr/bin/env node
/**
 * Build Checker Hook - Template
 *
 * Runs linters/type checkers after code edits.
 *
 * CUSTOMIZE:
 * 1. Update file path patterns for your project structure
 * 2. Update lint commands for your tools (ESLint, Ruff, etc.)
 * 3. Add additional checks as needed (type checking, tests, etc.)
 */
import { readFileSync } from 'fs';
import { execSync } from 'child_process';

// ============================================
// CONFIGURATION - CUSTOMIZE THESE VALUES
// ============================================

interface ProjectConfig {
  name: string;
  path: string;
  pathMatcher: (file: string) => boolean;
  lintCommand: string;
  successMessage: string;
}

const PROJECT_CONFIGS: ProjectConfig[] = [
  // Frontend Configuration
  {
    name: 'Frontend',
    path: 'frontend',
    pathMatcher: (file) => file.includes('/frontend/') || file.includes('/src/'),
    lintCommand: 'cd frontend && pnpm lint',
    // Alternative commands:
    // lintCommand: 'cd frontend && npm run lint',
    // lintCommand: 'cd client && yarn lint',
    successMessage: 'Frontend: No lint errors'
  },

  // Backend Configuration
  {
    name: 'Backend',
    path: 'backend',
    pathMatcher: (file) => file.includes('/backend/') || file.includes('/api/'),
    lintCommand: 'cd backend && python -m ruff check .',
    // Alternative commands:
    // lintCommand: 'cd backend && python -m pylint .',
    // lintCommand: 'cd server && npm run lint',
    successMessage: 'Backend: No lint errors'
  },

  // Add more configurations as needed:
  // {
  //   name: 'Shared',
  //   path: 'shared',
  //   pathMatcher: (file) => file.includes('/shared/'),
  //   lintCommand: 'cd shared && npm run lint',
  //   successMessage: 'Shared: No lint errors'
  // }
];

// ============================================
// HOOK LOGIC - Usually no changes needed
// ============================================

interface HookInput {
  cwd: string;
  tool_uses?: Array<{
    tool: string;
    parameters?: {
      file_path?: string;
    };
  }>;
}

async function main() {
  try {
    const input = readFileSync(0, 'utf-8');
    const data: HookInput = JSON.parse(input);
    const cwd = data.cwd;

    // Get edited files from tool uses
    const editedFiles = data.tool_uses?.filter(t =>
      t.tool === 'Edit' || t.tool === 'Write'
    ).map(t => t.parameters?.file_path || '') || [];

    if (editedFiles.length === 0) {
      process.exit(0);
    }

    const errors: string[] = [];

    // Check each configured project
    for (const config of PROJECT_CONFIGS) {
      const matchingFiles = editedFiles.filter(config.pathMatcher);

      if (matchingFiles.length > 0) {
        console.log(`🔍 Checking ${config.name} files...`);
        try {
          execSync(config.lintCommand, { cwd, stdio: 'pipe' });
          console.log(`✅ ${config.successMessage}`);
        } catch (err: any) {
          const output = err.stdout?.toString() || err.stderr?.toString() || '';
          // Skip if output indicates success despite exit code
          if (!output.includes('All checks passed') && !output.includes('0 problems')) {
            errors.push(`${config.name} lint errors:\n${output}`);
          }
        }
      }
    }

    // Report errors if any
    if (errors.length > 0) {
      console.log(`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  BUILD/LINT ERRORS DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`);
      errors.forEach(err => console.log(err + '\n'));
      console.log('Please fix these errors before continuing.');
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }

    process.exit(0);
  } catch (err) {
    // Don't fail the hook on errors - this prevents blocking the user
    process.exit(0);
  }
}

main();
