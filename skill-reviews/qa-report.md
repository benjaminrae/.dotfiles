# Skill Review: qa-report

**One-line summary:** A well-structured, single-file QA test-plan generator that passes the validator clean and has a strong, near-miss-aware trigger description; the main weaknesses are mild over-prescription, a large output-template that could be split out, and some generic content that restates QA common-sense. **Overall verdict: PASS (with minor WARNs).**

## Validator output

`validate_skill` returned `valid: true` with **zero errors and zero warnings**.

```
{"valid":true,"errors":[],"warnings":[],
 "info":[
   {"rule":"cc-extension-key","message":"frontmatter key `disable-model-invocation` is Claude-Code-only — not portable","file":"SKILL.md"},
   {"rule":"cc-extension-key","message":"frontmatter key `argument-hint` is Claude-Code-only — not portable","file":"SKILL.md"}],
 "stats":{"skill_md_lines":244,"description_chars":324,"reference_files":0}}
```

- SKILL.md is **244 lines** — under the 500-line ceiling.
- description is **324 chars** — well under 1024.
- name `qa-report` (line 2) matches the directory, lowercase + hyphen, ≤64 chars, no `claude`/`anthropic`. PASS.
- Two `info` findings only (Claude-Code-only frontmatter keys). Non-gating and acceptable for a Claude-Code-targeted dotfiles repo; not portable to other runtimes, worth a one-line awareness note but not a fix.
- **Eval count: 0.** `reference_files: 0` and there is no evals file. The REVIEW floor expects ≥3 evals; none exist. This is the single hard gap against the deterministic floor (see Finding F1).

**Floor result:** PASS on validator lint; **FAIL on the ≥3-evals requirement** (no evals present).

## Trigger probe

`test_triggers` was run with 10 hand-authored queries (5 should-trigger, 5 near-miss negatives) at 3 runs each. **The run is inconclusive: all 30 probes returned `infra_errors` (30/30) and the $3 budget cap was hit — `total: 10, passed: 0, failed: 0, infra_errors: 30`.** Per the harness contract, infra errors are *not* counted as "did not trigger," so this yields no signal. I fall back to a manual description analysis.

**Description (line 3):**
> "Analyzes a branch or PR diff and generates a comprehensive QA review report. Saves to the repository's existing QA-docs convention when one is detected, otherwise falls back to qa-reviews/{branch-name}.md. Use when the user wants to do QA, test a branch, review what to test, or prepare a test plan for a feature or bug fix."

Manual assessment against the intended should/shouldn't set:

- **Should trigger** ("generate a QA review report", "prepare a test plan for PR #482", "what to test on this branch", "do QA on this branch"): The lead verb phrase ("generates a comprehensive QA review report") and the explicit use-case list ("do QA, test a branch, review what to test, or prepare a test plan") directly cover all five intended positives. Strong match.
- **Near-miss exclusion:** The description does NOT mention posting PR comments or running a full multi-agent branch review, so it should stay quiet for those. However, the exclusion is *implicit* — there is no "Not for..." clause naming the sibling skills (`qa-pr-comment`, `branch-review`, `code-review`). Both QA siblings carry a reciprocal cross-reference (`qa-pr-comment`: "not for generating a test plan or report"; `branch-review`: "Not for posting QA results as a PR comment (use qa-pr-comment)"). qa-report is the odd one out with no reciprocal "Not for" pointer, raising collision risk on phrases like "QA before merge" / "review report" that `branch-review` also claims. See Finding F2.

**Trigger verdict (manual):** WARN — likely strong recall on positives, but missing explicit near-miss exclusion creates a real collision surface with `branch-review` and `qa-pr-comment`.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | WARN | Lint clean, but **0 evals** vs ≥3 expected (`reference_files: 0`, no evals file). | Add ≥3 evals (positive trigger, near-miss vs branch-review/qa-pr-comment, output-quality check). |
| Triggers | WARN | Strong positive coverage; **no explicit "Not for…" exclusion** while two siblings point back at it (collision on "review report"/"QA before merge"). | Add a near-miss clause naming `qa-pr-comment` (posting) and `branch-review` (multi-agent review). |
| Structure | WARN | Output template (lines 107–182) and category guidance (196–216) are long inline blocks; point-of-decision routing (Step 1a) is good and correctly inline. | Optionally move the report template to a one-level-deep reference file; keep decision logic inline. |
| Over-prescription | WARN | Mild absolute imperatives and capitalized "BEFORE", "NOT", "exactly" (lines 32, 36, 69); a "Final Check" hard checklist (224–229). | Soften absolute language; keep the convention-detection emphasis (it is load-bearing). |
| Conciseness | WARN | Category-Specific Guidance (196–216) and Priority Criteria (231–235) largely restate QA knowledge Claude already has. | Trim to repo-specific conventions; cut generic QA tutorials. |
| Workflow completeness | PASS | Clear 5 steps, convention-detection gate with worktree handling, fallback path, exit/present step. | None required. |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance scores, no "Red Flags–STOP" blocks. | None. |
| Supply chain | PASS | No bundled scripts; only inline read-only bash (`git`/`ls`/`grep`/`find`) scoped by `allowed-tools`. | None. |
| Hygiene | WARN | Hard-coded example date "2026-06-22" (line 67) is time-sensitive; `Agent` in allowed-tools but never used in body. | Use a placeholder date; drop `Agent` from `allowed-tools` or document its use. |

## Findings (ranked by severity)

### F1 — No evals (deterministic-floor gap) — Severity: High
The skill ships with **zero eval files** (`reference_files: 0`; nothing under the skill dir but `SKILL.md`). The REVIEW floor expects ≥3 evals, and the trigger MCP run was inconclusive (30/30 infra errors), so there is currently *no* automated evidence that this skill triggers correctly or produces a good report.
**Fix:** Add at least three evals: (1) a positive trigger ("generate a QA report for this branch"); (2) a near-miss that must route to `branch-review`/`qa-pr-comment`; (3) an output-quality eval asserting the report contains the convention-detection step and a priority-tagged test table. Re-run `test_triggers` once the harness budget allows.

### F2 — Missing explicit near-miss exclusion in description — Severity: Medium
Description (line 3) lists only positive use cases. Siblings explicitly disclaim qa-report's territory, but qa-report does not reciprocate. `branch-review` is described with "review report" and "QA before merge" — heavy overlap with qa-report's "do QA, ... prepare a test plan." Without a "Not for…" clause, ambiguous prompts ("QA review report before merge") can route to either skill.
**Fix:** Append, e.g.: "Not for posting QA results as a PR comment (use qa-pr-comment) or running a multi-agent branch/code review (use branch-review). This skill produces a written test plan." Stays under 1024 chars.

### F3 — Time-sensitive hard-coded date in example — Severity: Low
Line 67: `Writing QA report to 07_qa/2026-06-22-sdb-371-<slug>_07.md (detected ICM convention)`. A concrete past date in a template invites the model to copy it or anchor on it.
**Fix:** Replace with a placeholder, e.g. `<YYYY-MM-DD>-sdb-371-<slug>_07.md`.

### F4 — `Agent` granted but unused — Severity: Low
`allowed-tools` (line 5) includes `Agent`, but the body never dispatches a subagent — all work is inline. Granting an unused, powerful tool is needless surface.
**Fix:** Remove `Agent` from `allowed-tools`, or add an explicit step that delegates analysis of large diffs to a subagent and document it.

### F5 — Over-prescription / generic-knowledge restatement — Severity: Low
- Capitalized absolutes: "do this BEFORE choosing an output path" (line 32), "Honor it exactly" (line 36), "NOT unconditionally `qa-reviews/<branch>.md`" (line 69), and the "Final Check" mandatory checklist (lines 224–229). The convention-detection emphasis is justified (the skill states this is "a real, recurring mistake", line 34), but the volume of imperatives adds noise.
- Category-Specific Guidance (lines 196–216) and Priority Criteria (lines 231–235) mostly restate standard QA taxonomy (edge cases, injection, CORS, pagination limits) that a capable model already knows.
**Fix:** Keep the load-bearing convention-detection emphasis; soften decorative capitalization; trim generic QA tutorials to anything repo/convention-specific (e.g. the ICM `07_qa/` shape, which IS specific and worth keeping).

### F6 — Inline template length / optional reference split — Severity: Low
The report template (lines 107–182) plus category guidance push SKILL.md to 244 lines. Still under the 500 ceiling and no TOC requirement is triggered, but the large template is stable, rarely-edited content that suits a one-level-deep reference file, leaving the body focused on workflow/decisions.
**Fix (optional):** Move the markdown report skeleton to `references/report-template.md` and link it from Step 4.

## Recommendations (prioritized)

1. **Add ≥3 evals** (F1) and re-run `test_triggers` when budget allows — the only floor failure and the highest-value fix.
2. **Add an explicit "Not for…" near-miss clause** naming `qa-pr-comment` and `branch-review` (F2) to close the routing collision; the two siblings already point back, so this makes the triad consistent.
3. **De-time-stamp the example** (F3) and **drop the unused `Agent` tool** (F4) — trivial hygiene wins.
4. **Soften decorative absolutes and trim generic QA tutorial content** (F5), keeping the convention-detection logic, which is the skill's genuine differentiator.
5. **(Optional)** split the report template into a reference file (F6) to keep the body decision-focused.
