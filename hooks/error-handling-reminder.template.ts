#!/usr/bin/env node
/**
 * Error Handling Reminder Hook - Template
 *
 * Shows reminders about error handling best practices when
 * relevant files are edited.
 *
 * CUSTOMIZE:
 * 1. Update file patterns for your project
 * 2. Update reminder messages for your tech stack
 * 3. Add/remove reminders as needed
 */
import { readFileSync } from 'fs';

// ============================================
// CONFIGURATION - CUSTOMIZE THESE VALUES
// ============================================

interface ReminderConfig {
  name: string;
  fileMatcher: (file: string) => boolean;
  reminder: string;
}

const REMINDER_CONFIGS: ReminderConfig[] = [
  // Python Backend Reminder
  {
    name: 'Python Backend',
    fileMatcher: (file) =>
      file.endsWith('.py') &&
      (file.includes('backend/') || file.includes('api/') || file.includes('server/')),
    reminder: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ERROR HANDLING SELF-CHECK (Python)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Backend Changes Detected

   ❓ Did you add proper try-except blocks?
   ❓ Are exceptions logged with logger.error()?
   ❓ Are errors captured in your monitoring tool?
   ❓ Are appropriate HTTP exceptions raised?

   💡 Best Practices:
      - Use try-except for all I/O operations
      - Log errors with exc_info=True
      - Capture unexpected exceptions in Sentry/Datadog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`
  },

  // TypeScript/JavaScript Backend Reminder
  {
    name: 'Node.js Backend',
    fileMatcher: (file) =>
      (file.endsWith('.ts') || file.endsWith('.js')) &&
      (file.includes('server/') || file.includes('api/') || file.includes('backend/')),
    reminder: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ERROR HANDLING SELF-CHECK (Node.js)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Backend Changes Detected

   ❓ Did you add proper try-catch blocks?
   ❓ Are errors logged with proper context?
   ❓ Are async errors handled correctly?
   ❓ Are appropriate HTTP status codes returned?

   💡 Best Practices:
      - Wrap async operations in try-catch
      - Use error middleware for Express/Fastify
      - Include stack traces in development
      - Use structured logging (Winston, Pino)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`
  },

  // React/Frontend Reminder
  {
    name: 'React Frontend',
    fileMatcher: (file) =>
      (file.endsWith('.tsx') || file.endsWith('.jsx')) &&
      (file.includes('frontend/') || file.includes('src/') || file.includes('app/')),
    reminder: `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 ERROR HANDLING SELF-CHECK (React)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Frontend Changes Detected

   ❓ Did you add error boundaries where needed?
   ❓ Are API errors handled gracefully?
   ❓ Are loading/error states displayed to users?
   ❓ Are form validation errors shown clearly?

   💡 Best Practices:
      - Use ErrorBoundary for component errors
      - Handle API errors with try-catch or .catch()
      - Show user-friendly error messages
      - Log errors to monitoring service
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`
  }

  // Add more configurations as needed
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

    // Get edited files from tool uses
    const editedFiles = data.tool_uses?.filter(t =>
      t.tool === 'Edit' || t.tool === 'Write'
    ).map(t => t.parameters?.file_path || '') || [];

    if (editedFiles.length === 0) {
      process.exit(0);
    }

    // Track which reminders have been shown to avoid duplicates
    const shownReminders = new Set<string>();

    // Check each reminder configuration
    for (const config of REMINDER_CONFIGS) {
      if (shownReminders.has(config.name)) continue;

      const matchingFiles = editedFiles.filter(config.fileMatcher);

      if (matchingFiles.length > 0) {
        console.log(config.reminder);
        shownReminders.add(config.name);
      }
    }

    process.exit(0);
  } catch (err) {
    // Don't fail on hook errors
    process.exit(0);
  }
}

main();
