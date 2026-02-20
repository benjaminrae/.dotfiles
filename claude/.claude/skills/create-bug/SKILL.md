---
name: create-bug
description: Use when creating bug tickets in Jira. Triggers on requests to report bugs, log defects, or create bug tickets.
---

# Create Bug

Create a Jira bug using the Atlassian MCP, optionally linked to an epic.

## Required Information

Gather from the user before creating:

| Field | Required | Example |
|-------|----------|---------|
| Summary | Yes | "Login fails with 500 error" |
| Project Key | Yes | "SD", "SDB", "EP" |
| Description | Yes | Steps to reproduce, expected/actual behavior |
| Epic Key | No | "EP-100" |

## Process

**REQUIRED SKILL:** Use `create-jira-task` with:
- `issueTypeName`: "Bug"
- All other fields as provided by user

1. **Gather bug details** from user:
   - Summary (short title)
   - Description (steps to reproduce, expected vs actual, impact)
   - Project key
   - Epic key (if applicable)

2. **Create issue** using `create-jira-task` with:
   - `issueTypeName`: "Bug"
   - `projectKey`: user-provided
   - `summary`: user-provided
   - `description`: user-provided
   - `parent`: epic key if provided

3. **Return** the issue key and URL to the user

## Bug Description Template

When creating the description, include:

```markdown
## Summary
Brief description of the bug.

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Impact
How this affects users/system.

## Environment
- Service: (e.g., sites-matching, sites-db)
- Environment: (e.g., local Docker, staging, production)
```

## Example

User: "Create a bug for the TABLE_SITES error in sites-matching, link to EP-100"

Create using `create-jira-task` with:
- projectKey: "EP"
- issueTypeName: "Bug"
- summary: "Sites-matching missing TABLE_SITES configuration for STATUS operations"
- parent: "EP-100"
- description: (formatted bug description)

Result: EP-XXX - https://qualifyze-tech.atlassian.net/browse/EP-XXX