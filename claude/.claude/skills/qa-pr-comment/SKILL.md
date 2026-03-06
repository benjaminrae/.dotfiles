---
name: qa-pr-comment
description: Use when posting a manual QA summary comment on a GitHub PR after executing manual tests. Formats test results as a human-written PR comment with a scenario table and known issues section.
---

# QA PR Comment

Post a manual QA summary on a PR after executing tests from a QA review report.

## When to Use

- After running manual QA tests against a live system
- When the user asks to comment QA results on a PR

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

- Write in third person, factual tone — no "I tested" or "we verified"
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