---
name: qa-pr-comment
description: Use when posting a manual QA summary comment on a GitHub PR after executing manual tests. Formats results as a concise, plainly written PR comment with a scenario table and known issues section — for posting results after tests have run, not for generating a test plan or report.
---

# QA PR Comment

Post a manual QA summary on a PR after executing tests from a QA review report.

## When to Use

- After running manual QA tests against a live system
- When the user asks to comment QA results on a PR

## Report Only What Was Tested

Populate the tables only from tests that were actually executed in this session. Never invent PASS rows or fabricate results to fill the template. If no tests have been run yet, stop — run them first (or hand off to `qa-report` to plan them) before posting. Every row must trace to an observed result.

## Template

```markdown
## Manual QA

Tested against a running local instance with [relevant infrastructure context].

### Passed

| # | Scenario | Result |
|---|----------|--------|
| 1 | [Scenario description] → [expected outcome] | PASS |
| ... | ... | ... |

### Failed

| # | Scenario | Expected | Actual |
|---|----------|----------|--------|
| 1 | [Scenario description] | [expected] | [actual] |

### Known Issues

[Pre-existing issue] — tracked in [JIRA-LINK](url). [Brief note on how it relates to this PR's changes.]
```

## Guidelines

- Write plainly and factually in the third person: state what was tested and the result, e.g. "Scenario X passed" rather than "I tested X"
- Omit the **Failed** section entirely if all tests passed
- Omit the **Known Issues** section if there are none
- Keep scenario descriptions concise: `action → expected result`
- Link Jira tickets for any known issues found during testing
- Note whether the issue is pre-existing or introduced by the PR
- Include infrastructure context (e.g., "event publishing enabled", "gRPC disabled")

## Posting

Use `gh pr comment <number> --body` with a heredoc:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'EOF'
<comment content>
EOF
)"
```