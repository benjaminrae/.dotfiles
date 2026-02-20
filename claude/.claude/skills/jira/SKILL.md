---
name: jira
description: Use when creating Jira issues with full context - auto-detects project from repo, validates issue types, prompts for parent/epic, enriches description from git and conversation, previews before creation
---

# Create Jira Issue

Create Jira issues (Task, Story, Bug, Subtask) with intelligent defaults, validation, and context-aware descriptions.

## Workflow

```
1. INITIALIZE  →  Get cloud ID, detect repo → project key, detect branch ticket
2. GATHER INFO →  Validate issue type, ask for parent, offer branch linking
3. BUILD DESC  →  Collect context (git, conversation, code), ask format preference
4. PREVIEW     →  Show all fields, allow edits
5. CREATE      →  Create issue, add links, show result
```

## Step 1: Initialize

### Get Cloud ID

```
getAccessibleAtlassianResources()
→ Extract cloudId; construct base URL from the resource's url field
```

### Detect Repository

1. Try `git remote get-url origin` → parse repo name; fallback to directory name
2. Call `getVisibleJiraProjects` → if repo matches a project name/key, use it; otherwise ask

### Detect Branch Ticket

Parse `git branch --show-current` for ticket patterns:
- `{PROJ-316}-add-feature` → `{PROJ-316}`
- `feature/{BRANCH-TICKET}-new-api` → `{BRANCH-TICKET}`
- `main` → none

## Step 2: Gather Information

### Validate Issue Type

Always validate before creating: `getJiraProjectIssueTypesMetadata(cloudId, projectKey)`.

If requested type unavailable, list the available types for the project and ask which to use. **Type matching:** case-insensitive, partial match OK (e.g., "task" matches "Task").

**Subtask rules:** Require a parent Task or Story (not Epic). The `parent` field works for both Epic→Task/Story and Task/Story→Subtask hierarchies. If user requests Subtask without parent, prompt: "Subtasks need a parent Task or Story. Which issue should this be under?"

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

If search selected, use `searchJiraIssuesUsingJql` with project/type/status filters and present numbered results for selection.

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

**Always show preview before creating:**

```
┌─────────────────────────────────────────────────────┐
│ Preview: New Task in {projectKey}                   │
├─────────────────────────────────────────────────────┤
│ Type:        Task                                   │
│ Summary:     [summary]                              │
│ Parent:      {PROJ-316} [parent summary]            │
│ Link:        Relates to {BRANCH-TICKET}             │
├─────────────────────────────────────────────────────┤
│ Description:                                        │
│ [description content]                               │
└─────────────────────────────────────────────────────┘

Ready to create? (1) Yes (2) Edit summary (3) Edit description (4) Change parent (5) Cancel
```

Loop on edits until user confirms or cancels.

## Step 5: Create

### Create Issue

```
createJiraIssue(cloudId, projectKey, issueTypeName, summary, description, parent)
```

Description supports markdown formatting.

### Add Issue Link (if requested)

Jira issue linking requires a separate API call after creation. Check for link-related MCP tools first; try `editJiraIssue` via the update field as an alternative; if no tool available, tell user: "Created the task. To link it to {BRANCH-TICKET}, add the link manually in Jira." Supported link types: "blocks", "is blocked by", "relates to".

### Show Result

```
Created {projectKey}-NNN: [summary]
   {baseUrl}/browse/{projectKey}-NNN
   └── Relates to {BRANCH-TICKET}
```

Construct `baseUrl` from `getAccessibleAtlassianResources` response.

## Reference

See `mcp-reference.md` for MCP tool reference, optional fields, and error handling.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Skipping type validation | Always call `getJiraProjectIssueTypesMetadata` first |
| Skipping parent prompt | Always ask - even if user didn't mention one |
| No preview | Always show preview before `createJiraIssue` |
| Generic description | Use git/conversation context to enrich |
| Ignoring branch context | Check branch for ticket ID, offer linking |
| Hardcoding Jira URLs | Always construct URL from `getAccessibleAtlassianResources` response |
| Assuming project key | Always discover via `getVisibleJiraProjects` when not obvious from context |