---
name: branch-review
description: Use when a feature branch is ready for review or before merging to main
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

## Step 2: Optional analyses

AskUserQuestion multi-select: "Which additional analyses?"

| Option | Agent type |
|--------|-----------|
| Code smell detection | code-smell-detector |
| Cognitive load analysis | cognitive-load-analyzer |
| Test design review | test-design-reviewer |
| System walkthrough | system-walkthrough |
| PostgreSQL conventions | code-reviewer |

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

## Step 4.5: Validate findings

Launch finding-validator agent: "Read finding-validator.md. Validate findings in {tmp}/ for `{BRANCH}`. Return validated findings as text."

`run_in_background: true`, then `TaskOutput block: true`, `timeout: 300000`.

Write the returned text to `{tmp}/validated-findings.md`.

## Step 5: Compile report

General-purpose agent: "Read report-compiler.md. Compile `{BRANCH}` from {tmp}/. Selected: {selected_options}."

`run_in_background: true`, then `TaskOutput block: true`.

## Step 6: Summary

Print verdict, report path (`reviews/{SAFE}.md`), action item count.

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
