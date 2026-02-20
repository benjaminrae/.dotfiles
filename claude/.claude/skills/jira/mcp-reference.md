# Jira MCP Reference

## Quick Reference

| Step | MCP Tool |
|------|----------|
| Get cloud ID | `getAccessibleAtlassianResources` |
| List projects | `getVisibleJiraProjects` |
| Validate types | `getJiraProjectIssueTypesMetadata` |
| Search parent | `searchJiraIssuesUsingJql` |
| Get issue details | `getJiraIssue` |
| Lookup user ID | `lookupJiraAccountId` |
| Create issue | `createJiraIssue` |

## Optional Fields

These can be added if user requests or context suggests:

| Field | When to offer | MCP parameter |
|-------|---------------|---------------|
| Assignee | User mentions "assign to X" | `assignee_account_id` (use `lookupJiraAccountId` first) |
| Labels | Rarely needed | Via `additional_fields` |
| Components | Rarely needed | Via `additional_fields` |

**Keep it simple:** Don't prompt for optional fields unless user asks. The core flow focuses on summary, type, parent, description.

## Error Handling

| Error | Response |
|-------|----------|
| Cloud ID fetch fails | "Unable to connect to Jira. Try `/mcp` to re-authenticate the Atlassian MCP" |
| Project not found | "Project '{projectKey}' not found. Available: ..." → list projects |
| Parent doesn't exist | "Couldn't find {ID}. Would you like to search instead?" |
| Creation fails | Show Jira error, offer to retry with changes |

## JQL Patterns

**Search for parent issues:**
```
project = {projectKey} AND type in (Epic, Story, Task) AND status != Done AND summary ~ '{term}'
```