#!/usr/bin/env node
/**
 * Skill Activation Hook
 *
 * Analyzes user prompts and suggests relevant skills based on:
 * - Keywords in the prompt
 * - Intent patterns (regex matching)
 *
 * This hook is generic and works with any skill-rules.json configuration.
 * No customization needed - just update skill-rules.json for your project.
 */
import { readFileSync } from 'fs';
import { join } from 'path';

interface SkillTriggers {
  keywords?: string[];
  intentPatterns?: string[];
}

interface SkillConfig {
  type: string;
  enforcement: 'suggest' | 'warn' | 'block';
  priority: 'critical' | 'high' | 'medium' | 'low';
  description: string;
  promptTriggers?: SkillTriggers;
  fileTriggers?: {
    pathPatterns?: string[];
    pathExclusions?: string[];
    contentPatterns?: string[];
  };
  blockMessage?: string;
  skipConditions?: {
    sessionSkillUsed?: boolean;
    fileMarkers?: string[];
    envOverride?: string;
  };
}

interface SkillRules {
  version: string;
  description: string;
  skills: Record<string, SkillConfig>;
}

interface HookInput {
  cwd: string;
  prompt: string;
}

interface MatchedSkill {
  name: string;
  config: SkillConfig;
}

async function main() {
  try {
    const input = readFileSync(0, 'utf-8');
    const data: HookInput = JSON.parse(input);
    const prompt = data.prompt.toLowerCase();
    const cwd = data.cwd;

    // Load skill rules from project
    const rulesPath = join(cwd, '.claude', 'skills', 'skill-rules.json');
    let rules: SkillRules;

    try {
      rules = JSON.parse(readFileSync(rulesPath, 'utf-8'));
    } catch {
      // No skill rules found - silently exit
      process.exit(0);
    }

    const matchedSkills: MatchedSkill[] = [];

    // Check each skill for matches
    for (const [skillName, config] of Object.entries(rules.skills)) {
      // Skip entries that start with underscore (comments/metadata)
      if (skillName.startsWith('_')) continue;

      const triggers = config.promptTriggers;
      if (!triggers) continue;

      // Check keyword matches
      if (triggers.keywords) {
        const keywordMatch = triggers.keywords.some(kw => {
          // Skip placeholder keywords
          if (kw.startsWith('_')) return false;
          return prompt.includes(kw.toLowerCase());
        });
        if (keywordMatch) {
          matchedSkills.push({ name: skillName, config });
          continue;
        }
      }

      // Check intent pattern matches
      if (triggers.intentPatterns) {
        const intentMatch = triggers.intentPatterns.some(pattern => {
          try {
            return new RegExp(pattern, 'i').test(prompt);
          } catch {
            return false; // Invalid regex - skip
          }
        });
        if (intentMatch) {
          matchedSkills.push({ name: skillName, config });
        }
      }
    }

    // Output recommendations if skills matched
    if (matchedSkills.length > 0) {
      let output = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
      output += '🎯 SKILL ACTIVATION CHECK\n';
      output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';

      // Group by priority
      const critical = matchedSkills.filter(s => s.config.priority === 'critical');
      const high = matchedSkills.filter(s => s.config.priority === 'high');
      const medium = matchedSkills.filter(s => s.config.priority === 'medium');
      const low = matchedSkills.filter(s => s.config.priority === 'low');

      if (critical.length > 0) {
        output += '🚨 CRITICAL SKILLS:\n';
        critical.forEach(s => output += `  → ${s.name}\n`);
        output += '\n';
      }

      if (high.length > 0) {
        output += '📚 RECOMMENDED SKILLS:\n';
        high.forEach(s => output += `  → ${s.name}\n`);
        output += '\n';
      }

      if (medium.length > 0) {
        output += '📖 SUGGESTED SKILLS:\n';
        medium.forEach(s => output += `  → ${s.name}\n`);
        output += '\n';
      }

      if (low.length > 0) {
        output += '💡 OPTIONAL SKILLS:\n';
        low.forEach(s => output += `  → ${s.name}\n`);
        output += '\n';
      }

      output += 'ACTION: Use Skill tool BEFORE responding\n';
      output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';

      console.log(output);
    }

    process.exit(0);
  } catch (err) {
    // Log error for debugging but don't block
    console.error('Skill activation hook error:', err);
    process.exit(1);
  }
}

main();
