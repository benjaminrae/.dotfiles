# Jira MCP Reference

All tools are served by the `mcp-atlassian` MCP server (pre-configured site; no cloud ID needed).

## Quick Reference

| Step | MCP Tool |
|------|----------|
| List projects | `mcp__mcp-atlassian__jira_get_all_projects` |
| Search parent | `mcp__mcp-atlassian__jira_search` |
| Get issue details | `mcp__mcp-atlassian__jira_get_issue` |
| Lookup user | `mcp__mcp-atlassian__jira_get_user_profile` |
| Create issue | `mcp__mcp-atlassian__jira_create_issue` |
| Link issues | `mcp__mcp-atlassian__jira_create_issue_link` |

No issue-type metadata tool exists on this server; validate the type against the standard set (Task, Story, Bug, Subtask, Epic) and let `jira_create_issue` surface project-specific type errors.

## Optional Fields

These can be added if user requests or context suggests:

| Field | When to offer | How |
|-------|---------------|-----|
| Assignee | User mentions "assign to X" | `assignee` param (email, display name, or account ID; resolve with `mcp__mcp-atlassian__jira_get_user_profile` if needed) |
| Labels | Rarely needed | Via `additional_fields` (e.g. `{"labels": ["frontend"]}`) |
| Components | Rarely needed | `components` param (comma-separated names) |

**Keep it simple:** Don't prompt for optional fields unless user asks. The core flow focuses on summary, type, parent, description.

## Error Handling

| Error | Response |
|-------|----------|
| Connection / auth failure | "Unable to connect to Jira. Try `/mcp` to re-authenticate the Atlassian MCP" |
| Project not found | "Project '{projectKey}' not found. Available: ..." → list projects |
| Parent doesn't exist | "Couldn't find {ID}. Would you like to search instead?" |
| Creation fails | Show Jira error, offer to retry with changes |

## JQL Patterns

**Search for parent issues:**
```
project = {projectKey} AND type in (Epic, Story, Task) AND status != Done AND summary ~ '{term}'
```