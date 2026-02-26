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

| Agent | Type | File | Output |
|-------|------|------|--------|
| Automated Checks | general-purpose | automated-checks.md | automated-checks.md |
| Architecture | code-reviewer | architecture-review.md | architecture.md |
| Test Quality | code-reviewer | test-quality-review.md | test-quality.md |
| Standards | code-reviewer | standards-review.md | standards.md |

**Optional** (per Step 2):

| Agent | Type | File | Output |
|-------|------|------|--------|
| PostgreSQL | code-reviewer | postgresql-review.md | postgresql.md |
| Code Smells | code-smell-detector | built-in | own report |
| Cognitive Load | cognitive-load-analyzer | built-in | own report |
| Test Design | test-design-reviewer | built-in | own report |
| Walkthrough | system-walkthrough | built-in | own report |

Prompt: "Read <file>. Review `{BRANCH}` vs `main`. Write findings to {tmp}/<output>."

All `run_in_background: true`.

## Step 4: Wait

`TaskOutput` `block: true`, `timeout: 300000` per agent.

## Step 5: Compile report

General-purpose agent: "Read report-compiler.md. Compile `{BRANCH}` from {tmp}/. Selected: {selected_options}."

`run_in_background: true`, then `TaskOutput block: true`.

## Step 6: Summary

Print verdict, report path (`reviews/{SAFE}.md`), action item count.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Agents in foreground | Always `run_in_background: true` |
| Instructions in prompt | Point to instruction file |
| Stale temp dir | `rm -rf` before `mkdir` |
| Skipping selected option | Launch all chosen agents |
