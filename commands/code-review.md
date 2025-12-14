---
description: Perform a comprehensive architectural code review of recent changes
---

# Code Review

Perform a thorough architectural code review of the recent changes or specified files.

## Review Checklist

### 1. Architecture & Design
- [ ] Follows project patterns and conventions
- [ ] Proper separation of concerns
- [ ] No unnecessary coupling between modules
- [ ] Appropriate use of design patterns

### 2. Error Handling
- [ ] All errors are caught and handled appropriately
- [ ] Errors are logged with proper context
- [ ] User-facing errors are meaningful
- [ ] No silent failures

### 3. Type Safety
- [ ] No `any` types (or justified if used)
- [ ] Proper type definitions for all functions
- [ ] Interfaces/types are well-defined
- [ ] No type casting without validation

### 4. Security
- [ ] No hardcoded secrets or credentials
- [ ] Input validation on all user input
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (proper escaping)
- [ ] Authentication/authorization checks

### 5. Performance
- [ ] No N+1 query patterns
- [ ] Appropriate use of caching
- [ ] No unnecessary re-renders (frontend)
- [ ] Efficient data structures and algorithms

### 6. Testing
- [ ] New code is testable
- [ ] Edge cases considered
- [ ] Error paths tested
- [ ] Integration points covered

### 7. Code Quality
- [ ] Clear, descriptive naming
- [ ] DRY (no unnecessary duplication)
- [ ] Single responsibility principle
- [ ] Appropriate comments for complex logic

## Review Output Format

```markdown
## Code Review: [Feature/File Name]

### Summary
[Brief overview of changes and overall assessment]

### Strengths
- [Good practice 1]
- [Good practice 2]

### Issues Found

#### Critical
- [ ] [Issue description]
  - Location: `file:line`
  - Fix: [Suggested fix]

#### Important
- [ ] [Issue description]
  - Location: `file:line`
  - Fix: [Suggested fix]

#### Minor
- [ ] [Issue description]
  - Location: `file:line`
  - Fix: [Suggested fix]

### Recommendations
1. [Recommendation 1]
2. [Recommendation 2]
```

## Instructions

1. If no files are specified, review recent changes (check git diff or recently edited files)
2. Go through each item in the checklist
3. Document issues with specific file locations
4. Provide actionable fix suggestions
5. Prioritize issues by severity (Critical > Important > Minor)
