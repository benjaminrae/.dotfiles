---
name: create-jira-task-v2
description: Use when creating Jira issues with full context - auto-detects project from repo, validates issue types, prompts for parent/epic, enriches description from git and conversation, previews before creation
---

# Create Jira Task v2

Create Jira issues (Task, Story, Bug, Subtask) with intelligent defaults, validation, and context-aware descriptions.

## Repository Mappings

```
sites-db          → SD
subjects-db       → SDB
audits-public-api → APA
```

To add mappings: Edit this section when adopting for new repositories.

## Workflow

```
1. INITIALIZE
   ├── Get cloud ID
   ├── Detect repo → resolve project key
   └── Detect branch ticket (e.g., SD-316 from branch name)

2. GATHER INFO
   ├── Validate issue type against project
   ├── Ask for parent (ID / search / none)
   └── Offer branch linking if parent ≠ branch ticket

3. BUILD DESCRIPTION
   ├── Collect context (git, conversation, code)
   └── Ask: quick summary or detailed?

4. PREVIEW & CONFIRM
   └── Show all fields, allow edits

5. CREATE
   └── Create issue, add links, show result
```

## Step 1: Initialize

### Get Cloud ID

```
getAccessibleAtlassianResources()
→ Extract cloudId for subsequent calls
```

### Detect Repository

1. Try: `git remote get-url origin` → parse repo name
2. Fallback: current directory name
3. Look up in mappings table above
4. If no mapping: call `getVisibleJiraProjects` and ask user

### Detect Branch Ticket

```bash
git branch --show-current
```

Extract ticket ID using patterns:
- `SD-316-add-feature` → `SD-316`
- `feature/EP-100-new-api` → `EP-100`
- `main` → none

## Step 2: Gather Information

### Validate Issue Type

**Before creating, always validate the type exists:**

```
getJiraProjectIssueTypesMetadata(cloudId, projectKey)
→ Returns available types for this project
```

If requested type unavailable:
```
"SD doesn't have 'Story'. Available types:
 - Task
 - Bug
 - Sub-task
Which would you like?"
```

**Type matching:** Case-insensitive, partial match OK (e.g., "task" matches "Task")

**Subtask rules:**
- Subtasks require a parent Task or Story (NOT an Epic)
- The `parent` field works for both Epic→Task/Story and Task/Story→Subtask hierarchies
- If user requests Subtask without parent, prompt: "Subtasks need a parent Task or Story. Which issue should this be under?"

### Clarify Summary (if vague)

If user request is vague (e.g., "create a task for testing"), ask:

```
"What specifically should this task cover? For example:
 - Add unit tests for [specific service/component]
 - Fix [specific issue]
 - Implement [specific feature]"
```

Use their response to craft a clear, actionable summary (3-8 words, starts with verb).

### Ask for Parent

**Always ask - don't skip this step:**

If branch ticket detected, include it as an option:

```
"What's the parent for this issue?
 1. SD-316 (current branch)
 2. Enter different ticket ID
 3. Search for an epic/story
 4. No parent"
```

Without branch ticket:
```
"What's the parent for this issue?
 1. Enter ticket ID directly (e.g., EP-928)
 2. Search for an epic/story
 3. No parent"
```

**If search selected:**
```
searchJiraIssuesUsingJql(
  cloudId,
  jql: "project = {key} AND type in (Epic, Story, Task) AND status != Done AND summary ~ '{term}'"
)
```

Present numbered results for selection.

### Offer Branch Linking

**Only if:** Branch ticket detected AND parent differs from branch ticket.

```
"You're on branch SD-316. Link new task to SD-316?
 1. Blocks SD-316
 2. Is blocked by SD-316
 3. Relates to SD-316
 4. No link"
```

## Step 3: Build Description

### Gather Context

**Git context:**
```bash
git log main..HEAD --oneline    # Recent commits
git diff --stat                 # Changed files
```

**Conversation context:**
- Recent discussion topics
- Errors or issues mentioned
- Decisions made

**Code context:**
- Files read/edited in session
- Relevant snippets if specific function discussed

### Ask Format Preference

```
"How detailed should the description be?
 1. Quick summary (2-3 sentences)
 2. Detailed breakdown (Context, Requirements, Technical Notes, Acceptance Criteria)"
```

**Quick summary example:**
> Implements status notification for SetSiteAsDuplicatedCommandHandler. Part of SD-316 work to send status operation updates on site status changes.

**Detailed breakdown template:**
```markdown
## Context
[Why this task exists]

## Requirements
- [Specific requirement]

## Technical Notes
- [Implementation hints, patterns to follow]

## Acceptance Criteria
- [ ] [Testable outcome]
```

## Step 4: Preview & Confirm

**Always show preview before creating:**

```
┌─────────────────────────────────────────────────────┐
│ Preview: New Task in SD                             │
├─────────────────────────────────────────────────────┤
│ Type:        Task                                   │
│ Summary:     Add status notification to handler     │
│ Parent:      EP-928 (Tech Debt - SitesDB)          │
│ Link:        Relates to SD-316                      │
├─────────────────────────────────────────────────────┤
│ Description:                                        │
│ [description content]                               │
└─────────────────────────────────────────────────────┘

Ready to create?
 1. Yes, create it
 2. Edit summary
 3. Edit description
 4. Change parent
 5. Cancel
```

Loop on edits until user confirms or cancels.

## Step 5: Create

### Create Issue

```
createJiraIssue(
  cloudId,
  projectKey,
  issueTypeName,
  summary,
  description,    # Markdown supported
  parent          # Epic or parent task key
)
```

### Add Issue Link (if requested)

**Note:** Jira issue linking requires a separate API call after issue creation. The Atlassian MCP may not have a direct `createIssueLink` tool. Options:

1. **Check available tools** - Look for link-related MCP tools
2. **Use editJiraIssue** - Some setups allow adding links via the update field
3. **Manual fallback** - If no tool available, tell user: "Created the task. To link it to SD-316, add the link manually in Jira."

Link types to support: "blocks", "is blocked by", "relates to"

### Show Result

```
✅ Created SD-350: Add status notification to handler
   https://qualifyze-tech.atlassian.net/browse/SD-350
   └── Relates to SD-316
```

## Error Handling

| Error | Response |
|-------|----------|
| Cloud ID fetch fails | "Unable to connect to Jira. Try `/mcp` to re-authenticate the Atlassian MCP" |
| Project not found | "Project '{key}' not found. Available: ..." → list projects |
| Parent doesn't exist | "Couldn't find {ID}. Would you like to search instead?" |
| Creation fails | Show Jira error, offer to retry with changes |

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

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping type validation | Always call `getJiraProjectIssueTypesMetadata` first |
| Skipping parent prompt | Always ask - even if user didn't mention one |
| No preview | Always show preview before `createJiraIssue` |
| Generic description | Use git/conversation context to enrich |
| Ignoring branch context | Check branch for ticket ID, offer linking |
