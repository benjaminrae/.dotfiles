# Skill Review: qa-pr-comment

A tight, well-scoped single-file skill that passes the validator cleanly and is largely well-authored; the main gaps are zero evals (methodology floor is ≥3) and a couple of trigger/hygiene polish items. **Overall verdict: PASS with reservations** (ship-able, but add evals and tighten the description).

## Validator output

`validate_skill` ran against the directory and returned clean:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":63,"description_chars":279,"reference_files":0}}
```

- **Errors:** none.
- **Warnings:** none.
- **Spec floor checks (manual cross-check):**
  - name `qa-pr-comment` — lowercase + hyphens, matches dir, ≤64 chars, no `claude`/`anthropic`. PASS.
  - description 279 chars (≤1024), third person, no XML. PASS.
  - SKILL.md 63 lines (<500); no reference files, so the >100-line TOC rule does not apply. PASS.
  - **Evals: 0 found.** The directory contains only `SKILL.md` (confirmed via `find`). The REVIEW methodology floor is **≥3 evals**, so this is a deterministic-floor miss even though `validate_skill` does not gate on it. **FAIL on the eval floor.**

## Trigger probe

`test_triggers` was run with a 10-query set (5 should-trigger, 5 near-miss negatives covering `qa-report` test-plan/report and `branch-review`/code-review). **The run is inconclusive:** all 30 probe sessions returned infra errors and the `$3` budget cap was exhausted before any real trigger was measured.

```json
"summary":{"total":10,"passed":0,"failed":0,"infra_errors":30}
```

Every `pass` verdict is `null`; `trigger_rate` is 0 everywhere purely because sessions never completed, not because the skill failed to trigger. **Treat the probe as not-run.** Manual reasoning over the description below substitutes.

Manual trigger read (description as written):
- Positive surface is strong: "posting a manual QA summary comment on a GitHub PR after executing manual tests" names the key use case first with concrete nouns (PR, comment, manual tests).
- Near-miss exclusion is explicit and good: "not for generating a test plan or report" steers test-plan requests to `qa-report`. The sibling skills' own listings cross-reference this skill, reducing collision risk.
- Residual risk: "comment QA results on a PR" overlaps semantically with `qa-report`; the disambiguator hinges on the user signalling tests *already ran*. Acceptable, but worth an eval to confirm.

Recommend re-running `test_triggers` with a higher `budget_usd` (e.g. 8–10) and/or `runs_per_query: 2` once infra is healthy.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | WARN | Validator clean, but 0 evals vs methodology floor of ≥3 | Add ≥3 evals (positive trigger, near-miss negative, content/format eval) |
| Triggers | PASS | Key use case first, concrete nouns, explicit near-miss exclusion | Optional: add `branch-review`/`code-review` to the exclusion clause |
| Structure | PASS | Single file, facts each in one place, point-of-decision inline | None |
| Over-prescription | PASS | No MUST/CRITICAL/ALWAYS; one justified "Never" (line 17) | None |
| Conciseness | PASS | 63 lines, no padding, no explaining-what-Claude-knows | None |
| Workflow completeness | WARN | Has a stop-gate (line 17) but no failure path for "no PR number / gh not authed" | Add a one-line fallback note for missing PR or unauthenticated `gh` |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance, no Red-Flags-STOP | None |
| Supply chain | PASS | No scripts/executables; only an inline `gh` heredoc snippet | None |
| Hygiene | WARN | `gh` fully qualified; no time-sensitive phrasing; terms consistent; em-dash usage in prose | Trivial; optionally normalize em-dashes |

## Findings

### 1. Zero evals — deterministic-floor miss (highest severity)
**Evidence:** `find` over the directory returns only `/qa-pr-comment/SKILL.md`; validator stats report `"reference_files":0` and there is no `evals/` directory. The REVIEW methodology requires ≥3 evals.
**Why it matters:** Without evals, trigger behavior and output-format correctness are unverified — and the live `test_triggers` run was inconclusive (infra errors), so there is currently *no* empirical signal at all.
**Fix:** Add at least three evals:
- a positive trigger eval ("I ran the manual tests, comment the QA results on PR 482"),
- a near-miss negative ("generate a QA test plan for this branch" → must not trigger; `qa-report` owns it),
- a content eval asserting the posted comment omits the **Failed** / **Known Issues** sections when empty and contains only executed-test rows (the line 17 / lines 47-48 contract).

### 2. Inconclusive trigger probe (high — process, not a skill defect)
**Evidence:** `test_triggers` `summary: {infra_errors: 30}`, `total_cost_usd: 3` (budget cap hit). Every `pass` field is `null`.
**Why it matters:** The skill's headline value (correct triggering vs `qa-report`) is unproven by the probe.
**Fix:** Re-run with `budget_usd: 10` and `runs_per_query: 2` after infra recovery. Pairs with finding #1.

### 3. No failure/exit path for posting prerequisites (medium)
**Evidence:** The "Posting" section (lines 54–63) gives the `gh pr comment <PR_NUMBER> --body` heredoc but no guidance when the PR number is unknown or `gh` is unauthenticated. The only gate present is the "stop — run them first" condition for missing tests (line 17).
**Why it matters:** Workflow completeness — the skill defines the happy path but not the two most common real failure modes for the posting step.
**Fix:** Add one line, e.g. "If the PR number is unknown, resolve it with `gh pr view --json number`; if `gh` is unauthenticated, surface the auth error rather than reporting a posted result."

### 4. Minor trigger-exclusion gap (low)
**Evidence:** Description line 3 excludes only "generating a test plan or report" (i.e. `qa-report`). The skill registry shows sibling collisions with `branch-review` and `code-review` too.
**Why it matters:** A user saying "review the PR and comment the results" could ambiguously map here vs `branch-review` / `code-review`.
**Fix:** Optional — extend the negative clause: "...not for generating a test plan or report (use qa-report) or reviewing the diff (use branch-review/code-review)." Description is 279 chars, ample room under 1024.

### 5. Cosmetic — em-dash usage in prose (very low)
**Evidence:** e.g. line 3 "section — for posting", line 17 "stop — run them first". Consistent and not a banned construct; flagged only against the house human-voice preference.
**Fix:** None required.

## Recommendations

Prioritized:

1. **Add ≥3 evals** (finding #1) — the only item blocking a clean methodology pass. Cover one positive trigger, one near-miss negative against `qa-report`, and one output-format/content assertion.
2. **Re-run `test_triggers`** with a larger budget (finding #2) to replace the inconclusive probe with real data; feed any failures into `optimize_description`.
3. **Add a posting-failure line** (finding #3) for unknown PR number / unauthenticated `gh`.
4. **Optional polish:** widen the near-miss exclusion clause to name `branch-review` / `code-review` (finding #4).

No errors, no banned constructs, no supply-chain surface, and the content is concise and well-scoped — once evals exist and the probe is re-run green, this is a clean PASS.
