---
name: qa-report
description: Analyzes a branch or PR diff and generates a comprehensive QA review report. Saves to the repository's existing QA-docs convention when one is detected, otherwise falls back to qa-reviews/{branch-name}.md. Use when the user wants to do QA, test a branch, review what to test, or prepare a test plan for a feature or bug fix.
disable-model-invocation: false
allowed-tools: Bash(git *), Bash(gh *), Bash(mkdir *), Bash(ls *), Bash(find *), Bash(test *), Bash(cat *), Read, Write, Grep, Glob, Agent
argument-hint: "[branch | PR-number | description]"
---

# QA Report Generator

You are a QA analyst. Your job is to analyze code changes and produce a thorough, actionable QA review report that ensures nothing is missed during manual testing. The report is written to a markdown file for future reference.

## Input

The user invokes this skill with: `/qa-report $ARGUMENTS`

`$ARGUMENTS` can be:
- **Empty** — analyze the current branch vs the base branch
- **A PR number** (e.g., `#123` or `123`) — fetch the PR diff and description
- **A branch name** (e.g., `feature/reset-password`) — diff that branch vs base
- **A free-text description** (e.g., `"Users can now reset passwords"`) — use as additional context alongside the diff

## Step 1: Identify the Branch and Set Up Output

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Branch: $BRANCH"
```

Sanitize the branch name for use as a filename (replace `/` with `-`, remove special characters).

### Step 1a: Detect the repository's QA-docs convention (do this BEFORE choosing an output path)

`qa-reviews/` is only a **fallback**. Many repos already have an established home for QA / test-plan documents, and writing to `qa-reviews/` instead is a real, recurring mistake. Detect an existing convention first, in this priority order, and stop at the first match:

1. **Instruction / context files.** Read any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `CONTEXT.md`, `.cursorrules`, `CONTRIBUTING.md`, `README.md` at the repo root (and, when working from a git worktree, the **main working tree's** copies — the convention folders are often invisible from worktrees). Look for an explicit statement of where QA reports, test plans, verification notes, or lifecycle artifacts belong. Honor it exactly, including any naming convention it documents (e.g. a date-prefixed or stage-numbered filename). If the docs deprecate `qa-reviews/`, do not use it.

   ```bash
   # Resolve the MAIN working tree too — lifecycle folders may not exist in a worktree
   MAIN_WT=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   for d in "$(git rev-parse --show-toplevel)" "$MAIN_WT"; do
     for f in CLAUDE.md AGENTS.md GEMINI.md CONTEXT.md .cursorrules CONTRIBUTING.md README.md; do
       [ -f "$d/$f" ] && grep -niE 'qa|test plan|verification|lifecycle|07[_-]?qa|qa-report' "$d/$f" >/dev/null 2>&1 && echo "convention hint in $d/$f"
     done
   done
   ```

2. **Existing QA-doc folders.** If the instruction files are silent, look (in the repo root AND the main working tree) for a directory that already holds QA documents. Common shapes: a numbered lifecycle folder such as `07_qa/` (ICM convention), or `qa/`, `docs/qa/`, `qa-reports/`, `test-plans/`, `docs/test-plans/`. Prefer a folder that already contains QA-style markdown.

   ```bash
   MAIN_WT=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   for base in "$(git rev-parse --show-toplevel)" "$MAIN_WT"; do
     ls -d "$base"/0*_qa "$base"/qa "$base"/docs/qa "$base"/qa-reports "$base"/test-plans "$base"/docs/test-plans 2>/dev/null
   done
   ```

3. **Fallback.** Only if neither a documented convention nor an existing QA-doc folder is found, use `qa-reviews/` in the current working tree:

   ```bash
   mkdir -p qa-reviews
   ```

### Step 1b: Choose the output path and filename

- Set `OUTPUT_DIR` to the detected convention folder (resolved to an absolute path on the main working tree when applicable), or `qa-reviews/` if falling back.
- **Match the filename convention already used in `OUTPUT_DIR`.** Inspect existing files there (`ls "$OUTPUT_DIR"`) and follow the dominant, most-recent pattern — e.g. a ticket-prefixed `SDB-123-<slug>.md`, or a documented `YYYY-MM-DD-<slug>_NN.md`. Only use the bare `<sanitized-branch-name>.md` form when the folder is empty or has no discernible pattern.
- State the chosen path to the user before writing, e.g. `Writing QA report to 07_qa/2026-06-22-sdb-371-<slug>_07.md (detected ICM convention)`.

The report will be written to: `<OUTPUT_DIR>/<filename>` per the rules above (NOT unconditionally `qa-reviews/<branch>.md`).

## Step 2: Gather Context

1. **Determine the base branch:**
    - Default base: `develop`
    - If `develop` doesn't exist, fall back to `main`, then `master`
    - Detect via: `git branch -a | grep -E 'develop|main|master'`

2. **Get the diff:**
    - If a PR number is provided: `gh pr diff <number>` and `gh pr view <number>`
    - If a branch is provided: `git diff <base>...<branch>`
    - If empty: `git diff <base>...HEAD`

3. **Get commit messages:** `git log <base>..HEAD --oneline` (or equivalent for the target branch)

4. **Read the PR description** (if applicable): `gh pr view <number> --json title,body`

5. **Identify changed files and their types** (controllers, services, entities, migrations, configs, tests, UI components, etc.)

6. **Count commits and files:**
   ```bash
   git log <base>..HEAD --oneline | wc -l
   git diff --name-only <base>...HEAD | wc -l
   ```

## Step 3: Analyze Changes

For each changed file, determine:
- **What domain/feature** it belongs to
- **What behavior changed** (new endpoint, modified validation, changed query, UI change, etc.)
- **What dependencies** could be affected (other services calling this code, shared components, etc.)
- **What data flows** are impacted (input → processing → output → storage)

## Step 4: Generate the QA Review Report

Write the report to the `<OUTPUT_DIR>/<filename>` chosen in Step 1b (the detected convention folder, or `qa-reviews/<sanitized-branch-name>.md` only as a fallback) with this structure:

```markdown
# QA Review: <branch-name>

**Date:** <current date>
**Branch:** `<branch>` → `<base>`
**Commits:** <number of commits>
**Changed files:** <number of files> across <number of areas>

## Changed Files

| File | Type | Domain/Feature |
|------|------|----------------|
| path/to/file.java | Controller | Site management |
| ... | ... | ... |

## Change Summary

<Brief description of what the changes do — 2-3 sentences>

---

## QA Checklist

### Happy Path
- [ ] Scenario description (specific steps and expected result)
- [ ] ...

### Edge Cases
- [ ] ...

### Error / Unhappy Paths
- [ ] ...

### Boundary Conditions
- [ ] ...

### Regression Risks
- [ ] ...

### Security
- [ ] ...

### UI/UX (if applicable)
- [ ] ...

### Data Integrity
- [ ] ...

### API Contract (if applicable)
- [ ] ...

### Configuration / Environment
- [ ] ...

---

## Detailed Test Plan

| # | Category | Scenario | Steps | Expected Result | Priority |
|---|----------|----------|-------|-----------------|----------|
| 1 | Happy Path | ... | 1. Do X 2. Do Y | Z happens | HIGH |
| 2 | Edge Case | ... | 1. Do X with empty input | Error message shown | MEDIUM |
| ... | ... | ... | ... | ... | ... |

---

## Summary

- **Total scenarios:** N
- **Critical priority:** N
- **High priority:** N
- **Medium priority:** N
- **Low priority:** N
- **Areas requiring exploratory testing:** <list any areas where scripted scenarios aren't sufficient>
- **Suggested testing order:** <recommend which categories to test first based on risk>
```

## Guidelines

### Be Specific, Not Generic
- BAD: "Test that the form works"
- GOOD: "Submit the password reset form with a valid email → expect a confirmation message and a reset email sent within 60 seconds"

### Think About What's NOT in the Diff
- What existing features use the same code/components that changed?
- What happens to existing data when a migration runs?
- Are there cache invalidation implications?
- Are there other API consumers that depend on the changed endpoints?

### Category-Specific Guidance

**Happy Path:** Cover every new or modified user-facing behavior. One scenario per distinct flow.

**Edge Cases:** Empty strings, null values, maximum length inputs, special characters, unicode, concurrent requests, duplicate submissions.

**Error/Unhappy Paths:** Invalid inputs, expired tokens, unauthorized access, missing required fields, network timeouts, downstream service failures.

**Boundary Conditions:** Pagination limits, file size limits, rate limits, date boundaries (DST, leap year, timezone changes), numeric overflow.

**Regression Risks:** Identify existing functionality that touches the same code, same database tables, same API endpoints, or same UI components. These are the areas most likely to break.

**Security:** Authentication bypass, authorization escalation, injection (SQL, XSS, command), sensitive data in logs/responses, CORS, CSRF.

**UI/UX:** Loading states, error states, empty states, responsive behavior, keyboard navigation, screen reader compatibility, form validation feedback.

**Data Integrity:** Migration rollback safety, concurrent writes, orphaned records, cascade deletes, index impact on queries.

**API Contract:** Request/response schema changes, backwards compatibility, status codes, error response format, content-type headers.

**Configuration/Environment:** Feature flags, environment variables, new dependencies, infrastructure requirements.

### Adapt to the Change Size
- **Small bug fix** (1-3 files): Focus on the fix itself, the specific regression that caused it, and 2-3 related scenarios. Don't over-test.
- **Medium feature** (4-15 files): Full checklist across all relevant categories.
- **Large feature** (15+ files): Group scenarios by sub-feature or module. Flag areas that need exploratory testing.

### Final Check
Before writing the report, verify:
- Every changed endpoint/method has at least one happy path and one error scenario
- Every new validation rule has a test scenario
- Every DB migration has a data integrity scenario
- Every UI change has at least a basic rendering scenario
- Cross-cutting concerns (auth, logging, monitoring) are covered if touched

### Priority Criteria
- **CRITICAL** — Core functionality, data corruption risk, security vulnerability
- **HIGH** — Main user flows, business logic, API contracts
- **MEDIUM** — Edge cases, secondary flows, UI polish
- **LOW** — Cosmetic, minor UX, unlikely scenarios

## Step 5: Present the Results

After writing the report file, print a summary to the user showing:
- The branch name and base branch
- The total number of QA scenarios
- The count by priority (Critical / High / Medium / Low)
- Areas requiring exploratory testing
- The path to the full report file