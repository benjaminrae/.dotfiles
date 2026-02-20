---
name: create-jira-task
description: Use when you need to create a Jira task, optionally linked to an epic. Triggers on requests to add tickets, create issues, or log work items in Jira.
---

# Create Jira Task

Create a Jira task using the Atlassian MCP, optionally linked to an epic.

## Required Information

Gather from the user before creating:

| Field | Required | Example |
|-------|----------|---------|
| Summary | Yes | "Fix login timeout issue" |
| Project Key | Yes | "SD", "SDB", "EP" |
| Description | No | Markdown supported |
| Epic Key | No | "EP-928" |
| Issue Type | No | "Task" (default), "Bug", "Story" |

## Process

1. **Get cloud ID** using `getAccessibleAtlassianResources`
2. **Create issue** using `createJiraIssue` with:
   - `cloudId`: from step 1
   - `projectKey`: user-provided
   - `issueTypeName`: "Task" (or user-specified)
   - `summary`: user-provided
   - `description`: user-provided (optional, Markdown)
   - `parent`: epic key if linking to an epic

3. **Return** the issue key and URL to the user

## Example

User: "Create a task in SD to update the README, link it to EP-928"

```
1. Get cloud ID → 9119a183-9ece-4240-a4bc-b796fda3c9ed
2. Create issue:
   - projectKey: "SD"
   - issueTypeName: "Task"
   - summary: "Update the README"
   - parent: "EP-928"
3. Return: SD-321 - https://qualifyze-tech.atlassian.net/browse/SD-321
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing project key | Ask user which project (SD, SDB, etc.) |
| Epic key vs Epic ID | Use the key (EP-928), not numeric ID |
| Wrong issue type name | Use exact names: "Task", "Bug", "Story" |