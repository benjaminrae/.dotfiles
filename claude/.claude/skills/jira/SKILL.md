---
name: jira
description: Use when creating Jira issues with full context - auto-detects project from repo, validates issue types, prompts for parent/epic, enriches description from git and conversation, previews before creation
---

# Create Jira Issue

Create Jira issues (Task, Story, Bug, Subtask) with intelligent defaults, validation, and context-aware descriptions.

**Prerequisite:** the `mcp-atlassian` MCP server must be connected. It uses a pre-configured Atlassian site, so no cloud ID lookup is needed. If a tool call fails with a connection/auth error, tell the user to run `/mcp` to re-authenticate.

## Workflow

```
1. INITIALIZE  →  Detect repo → project key, detect branch ticket
2. GATHER INFO →  Validate issue type, ask for parent, offer branch linking
3. BUILD DESC  →  Collect context (git, conversation, code), ask format preference
4. PREVIEW     →  Show all fields, allow edits
5. CREATE      →  Create issue, add links, show result
```

## Step 1: Initialize

### Detect Repository

1. Try `git remote get-url origin` → parse repo name; fallback to directory name
2. Call `mcp__mcp-atlassian__jira_get_all_projects` → if repo matches a project name/key, use it; otherwise ask

### Detect Branch Ticket

Parse `git branch --show-current` for ticket patterns:
- `{PROJ-316}-add-feature` → `{PROJ-316}`
- `feature/{BRANCH-TICKET}-new-api` → `{BRANCH-TICKET}`
- `main` → none

## Step 2: Gather Information

### Validate Issue Type

`mcp-atlassian` has no issue-type metadata tool, so confirm the type against the standard set (Task, Story, Bug, Subtask, Epic) before creating. **Type matching:** case-insensitive, partial match OK (e.g., "task" matches "Task"). If `jira_create_issue` later rejects the type as unavailable for the project, relay the error's list of valid types and ask which to use.

**Subtask rules:** Require a parent Task or Story (not Epic). Pass the parent via `additional_fields` (`{"parent": "PROJ-123"}`); the `parent` field works for both Epic→Task/Story and Task/Story→Subtask hierarchies. If user requests Subtask without parent, prompt: "Subtasks need a parent Task or Story. Which issue should this be under?"

**Bug issues:** Use the description template from `bug-template.md`.

### Clarify Summary (if vague)

If the request is vague (e.g., "create a task for testing"), ask what specifically the task should cover. Suggest concrete examples like "Add unit tests for [component]" or "Fix [specific issue]". Use their response to craft a clear, actionable summary (3-8 words, starts with verb).

### Ask for Parent

**Always ask -- do not skip this step.**

With branch ticket detected, offer these options:
1. Use `{BRANCH-TICKET}` (current branch)
2. Enter a different ticket ID
3. Search for an epic/story
4. No parent

Without branch ticket, offer: (1) enter ID directly, (2) search, (3) no parent.

If search selected, use `mcp__mcp-atlassian__jira_search` with project/type/status filters and present numbered results for selection.

### Offer Branch Linking

**Only if** branch ticket detected AND parent differs from branch ticket.

Prompt with link type options:
1. Blocks `{BRANCH-TICKET}`
2. Is blocked by `{BRANCH-TICKET}`
3. Relates to `{BRANCH-TICKET}`
4. No link

## Step 3: Build Description

### Gather Context

- **Git:** `git log main..HEAD --oneline`, `git diff --stat`
- **Conversation:** recent topics, errors, decisions
- **Code:** files read/edited, relevant snippets

### Ask Format Preference

Ask: "How detailed should the description be?"
1. **Quick summary** -- 2-3 sentences covering what and why
2. **Detailed breakdown** -- structured with Context, Requirements, Technical Notes, Acceptance Criteria sections

**Quick summary example:**
> Implements status notification for the command handler. Part of {BRANCH-TICKET} work to send updates on status changes.

**Detailed breakdown** uses markdown headings for each section with bullet points under Requirements and checkboxes under Acceptance Criteria.

**Bug issues:** Follow `bug-template.md` instead of the above templates.

## Step 4: Preview & Confirm

**Always show a preview before creating.** Format it however reads cleanly in the user's terminal, but include every field that will be sent: project key, type, summary, parent (with its summary, if any), link (type + target, if any), and the full description.

Then ask the user to confirm or edit, offering at least: create as-is, edit summary, edit description, change parent, cancel. Loop on edits until the user confirms or cancels.

## Step 5: Create

### Create Issue

```
mcp__mcp-atlassian__jira_create_issue(
  project_key, summary, issue_type, description,
  additional_fields  # parent/epic link, e.g. {"parent": "PROJ-123"} or {"epic_link": "EPIC-123"}
)
```

Description supports markdown formatting. The returned issue object includes the issue key and its URL — use those when showing the result.

### Add Issue Link (if requested)

Jira issue linking is a separate call after creation: `mcp__mcp-atlassian__jira_create_issue_link(link_type, inward_issue_key, outward_issue_key)`. Map the chosen relationship to `link_type` ("Blocks", "Relates to", etc.) and set the inward/outward keys accordingly (the new issue and `{BRANCH-TICKET}`). Only if that call fails, fall back to telling the user: "Created the task. To link it to {BRANCH-TICKET}, add the link manually in Jira."

### Show Result

```
Created {projectKey}-NNN: [summary]
   {issueUrl}
   └── Relates to {BRANCH-TICKET}
```

Use the issue key and URL returned by `jira_create_issue`.

## Reference

See `mcp-reference.md` for MCP tool reference, optional fields, and error handling.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping type validation | Confirm the type against the standard set before creating |
| Skipping parent prompt | Always ask - even if user didn't mention one |
| No preview | Always show preview before `mcp__mcp-atlassian__jira_create_issue` |
| Generic description | Use git/conversation context to enrich |
| Ignoring branch context | Check branch for ticket ID, offer linking |
| Hardcoding Jira URLs | Use the issue URL returned by `jira_create_issue` |
| Assuming project key | Always discover via `mcp__mcp-atlassian__jira_get_all_projects` when not obvious from context |