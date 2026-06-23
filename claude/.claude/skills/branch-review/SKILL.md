---
name: branch-review
description: 'Use when reviewing a feature branch or PR before merging — "review this branch", "code review", "review report", "QA before merge". Dispatches parallel review agents (architecture, tests, standards, automated checks) and compiles one report. Not for posting QA results as a PR comment (use qa-pr-comment), a security-only pass (use security-review), or a single-diff inline review (use code-review).'
---

## Overview

Dispatches background agents to temp files; a compiler agent produces the report.

## Step 1: Setup

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
SAFE=$(echo "$BRANCH" | sed 's/[\/]/-/g; s/[^a-zA-Z0-9._-]//g')
rm -rf "reviews/.tmp/${SAFE}/" && mkdir -p "reviews/.tmp/${SAFE}/"
```

Append `reviews/.tmp/` to `.gitignore` if missing.

## Step 1.5: Pre-compute diff

Generate the diff and changed file list **before** launching any agents. Agents must not run `git diff` themselves.

```bash
git diff ${BASE_BRANCH}...${BRANCH} > reviews/.tmp/${SAFE}/diff.txt
git diff --name-only ${BASE_BRANCH}...${BRANCH} > reviews/.tmp/${SAFE}/changed-files.txt
```

If BASE_BRANCH is not provided then ask for it.

## Step 1.6: Detect the code-review docs convention

`reviews/` is only a **fallback** for the final report. Many repos already have an established home for code-review / review-report documents, and dropping the report in `reviews/` instead is a real, recurring mistake. Detect an existing convention first, in this priority order, and stop at the first match. (This only affects the FINAL report destination — the `reviews/.tmp/` scratch dir stays where it is.)

1. **Instruction / context files.** Read any of `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `CONTEXT.md`, `.cursorrules`, `CONTRIBUTING.md`, `README.md` at the repo root (and, when working from a git worktree, the **main working tree's** copies — these convention folders are often invisible from worktrees). Look for an explicit statement of where code reviews / review reports / lifecycle artifacts belong. Honor it exactly, including any documented naming convention (e.g. a date-prefixed or stage-numbered filename). If the docs deprecate `reviews/`, do not use it.

   ```bash
   MAIN_WT=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   for d in "$(git rev-parse --show-toplevel)" "$MAIN_WT"; do
     for f in CLAUDE.md AGENTS.md GEMINI.md CONTEXT.md .cursorrules CONTRIBUTING.md README.md; do
       [ -f "$d/$f" ] && grep -niE 'code.?review|review report|lifecycle|06[_-]?code.?review' "$d/$f" >/dev/null 2>&1 && echo "convention hint in $d/$f"
     done
   done
   ```

2. **Existing review-doc folders.** If the instruction files are silent, look (in the repo root AND the main working tree) for a directory that already holds review documents. Common shapes: a numbered lifecycle folder such as `06_code-review/` (ICM convention), or `code-reviews/`, `docs/reviews/`, `docs/code-reviews/`. Prefer a folder that already contains review-style markdown. Do **not** treat `reviews/.tmp/` (this skill's own scratch dir) as a convention.

   ```bash
   MAIN_WT=$(git worktree list --porcelain | awk '/^worktree /{print $2; exit}')
   for base in "$(git rev-parse --show-toplevel)" "$MAIN_WT"; do
     ls -d "$base"/0*_code-review "$base"/0*_code_review "$base"/code-reviews "$base"/docs/reviews "$base"/docs/code-reviews 2>/dev/null
   done
   ```

3. **Fallback.** Only if neither a documented convention nor an existing review-doc folder is found, use `reviews/` in the current working tree.

**Choose `REPORT_DIR` and filename:** set `REPORT_DIR` to the detected folder (resolved to an absolute path on the main working tree when applicable), or `reviews/` if falling back. **Match the filename convention already used in `REPORT_DIR`** — inspect existing files (`ls "$REPORT_DIR"`) and follow the dominant, most-recent pattern (e.g. ticket-prefixed `SDB-123-<slug>.md`, or a documented `YYYY-MM-DD-<slug>_NN.md`); only use the bare `{SAFE}.md` form when the folder is empty or patternless. Carry `REPORT_DIR/<filename>` (call it `REPORT_PATH`) into Steps 5 and 6, and state it to the user before compiling.

## Step 2: Optional analyses

AskUserQuestion multi-select: "Which additional analyses?"

| Option | Agent type |
|--------|-----------|
| Code smell detection | code-smell-detector |
| Cognitive load analysis | cognitive-load-analyzer |
| Test design review | test-design-reviewer |
| System walkthrough | system-walkthrough |
| PostgreSQL conventions | general-purpose (postgresql-review.md; reads the `postgresql-guidelines` skill's conventions reference if installed, else falls back to general PostgreSQL best practices) |

None = base review only.

## Step 3: Launch agents

`{tmp}` = `reviews/.tmp/{SAFE}`. Agent files in `~/.claude/skills/branch-review/agents/`.

**Base** (always):

| Agent               | Type            | File                   | Output              |
|---------------------|-----------------|------------------------|---------------------|
| Automated Checks    | general-purpose | automated-checks.md    | automated-checks.md |
| Architecture        | general-purpose | architecture-review.md | architecture.md     |
| Test Quality        | general-purpose | test-quality-review.md | test-quality.md     |
| Standards           | general-purpose | standards-review.md    | standards.md        |
| General Code Review | code-reviewer   | built-in               | core-review.md      |

**Optional** (per Step 2):

| Agent          | Type                    | File                 | Output        |
|----------------|-------------------------|----------------------|---------------|
| PostgreSQL     | general-purpose         | postgresql-review.md | postgresql.md |
| Code Smells    | code-smell-detector     | built-in             | own report    |
| Cognitive Load | cognitive-load-analyzer | built-in             | own report    |
| Test Design    | test-design-reviewer    | built-in             | own report    |
| Walkthrough    | system-walkthrough      | built-in             | own report    |

Prompt for base agents: "Read <file>. Review `{BRANCH}` using diff at {tmp}/diff.txt and changed files at {tmp}/changed-files.txt. Return your findings as text output."

Prompt for optional agents: "Read <file>. Review `{BRANCH}` vs `main`. Return your findings as text output."

All `run_in_background: true`.

After each agent completes via `TaskOutput`, write the returned text to `{tmp}/<output>` yourself (the orchestrator). Agents must NOT write files — they return findings as text.

## Step 4: Wait

`TaskOutput` `block: true`, `timeout: 300000` per agent.

If an agent times out or errors, record it as failed and continue — do not abort the run. Write nothing for its `{tmp}/<output>` file; the compiler will mark that section **AGENT FAILED -- rerun review**. Proceed to Step 5 once every other base output exists.

## Step 4.5: Validate findings

Launch finding-validator agent: "Read finding-validator.md. Validate findings in {tmp}/ for `{BRANCH}`. Return validated findings as text."

`run_in_background: true`, then `TaskOutput block: true`, `timeout: 300000`.

Write the returned text to `{tmp}/validated-findings.md`.

## Step 5: Compile report

General-purpose agent: "Read report-compiler.md. Compile `{BRANCH}` from {tmp}/. Write the final report to `{REPORT_PATH}` (do NOT default to `reviews/{branch}.md`). Selected: {selected_options}."

`run_in_background: true`, then `TaskOutput block: true`.

## Step 6: Summary

Print verdict, report path (`{REPORT_PATH}`), action item count.

## Common Mistakes

| Mistake                          | Fix                                                                |
|----------------------------------|--------------------------------------------------------------------|
| Agents in foreground             | Always `run_in_background: true`                                   |
| Instructions in prompt           | Point to instruction file                                          |
| Stale temp dir                   | `rm -rf` before `mkdir`                                            |
| Skipping selected option         | Launch all chosen agents                                           |
| Agents run `git diff` themselves | Pre-compute diff in Step 1.5; agents read the file                 |
| Agents write files directly      | Agents return text; orchestrator writes to `{tmp}/`                |
| No diff file = hallucination     | Abort if `git diff` fails — never launch agents without valid diff |
| Report dumped in `reviews/`      | Detect the repo's review-docs convention first (Step 1.6); `reviews/` is only a fallback |
| Convention folder missed in worktree | Check the main working tree too — lifecycle folders are invisible from worktrees |
