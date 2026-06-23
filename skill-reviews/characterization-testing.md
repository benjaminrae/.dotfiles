# Skill Review: characterization-testing

A tight, well-scoped single-file skill that teaches the characterization-testing loop cleanly; it passes the validator with zero findings and triggers correctly, with only minor conciseness and one structural nit. **Overall verdict: PASS (ship as-is; optional polish only).**

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` returned a clean result:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":97,"description_chars":323,"reference_files":0}}
```

- **0 errors, 0 warnings, 0 info.** Nothing to ignore or justify.
- Body is 97 lines (well under the 500-line limit).
- Description is 323 chars (within 1–1024).
- Zero reference files — a single self-contained SKILL.md, so the "references one level deep / TOC if >100 lines" rule does not apply.
- Name `characterization-testing` is lowercase+hyphen, matches the directory name, contains no "claude"/"anthropic", and is ≤64 chars.

Manual note on eval limits: the only structural floor that warrants a flag is **≥3 evals** — this skill bundles **no eval file** (`reference_files: 0`, no `evals/` directory). The agentskills validator did not gate on it, but the skill-craft methodology expects evals to exist. See Findings.

## Trigger probe

Run via `mcp__plugin_oberskills_skill-eval__test_triggers` (haiku probe sessions, claude_code preset). The harness suffered heavy infrastructure failures this session (25 infra errors in run 1, 6 in run 2), so several queries returned `pass: null` — these are infra noise, **not** genuine non-triggers, and are excluded from judgment.

Valid signal collected across both runs:

| Query | Expected | Trigger rate (clean runs) | Verdict |
|-------|----------|---------------------------|---------|
| "refactor this old payment module but it has no tests, how do I make a safety net first?" | trigger | 1/1 | PASS |
| "legacy function has no tests… lock down its current behavior before I change anything" | trigger | 2/2 | PASS |
| "How do I write characterization tests for untested code?" | trigger | 1/1 | PASS |
| "modify a 500-line untested class that nobody understands… where do I start?" | trigger | 1/1 | PASS |
| "I'm building a brand new feature, help me TDD it from scratch" | no-trigger | 0 (clean) | PASS |

Summary across clean runs: **5 should-trigger queries fired at rate 1.0; the one negative with clean signal stayed quiet.** No false positives and no false negatives were observed in any non-infra run. The remaining negatives (existing test suite → refactoring-guide; new UserService unit tests → TDD; security PR review; flaky-test debugging) could not be confirmed this session due to infra errors, but the description's explicit exclusion clause ("Not for: writing tests for new code (use TDD) or refactoring code that already has tests (use refactoring-guide)") gives strong reason to expect correct suppression.

**Trigger verdict: PASS** on available evidence; recommend a re-run when the eval harness is healthy to confirm the unverified negatives.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | PASS | 0 errors / 0 warnings. Caveat: no bundled evals despite skill-craft's ≥3-eval expectation. | Add an `evals/` set (3+) to lock trigger + content behavior. |
| Triggers | PASS | Third person, key use case first, concrete nouns ("untested legacy code", "safety net"), explicit near-miss exclusion. | None. Optionally split exclusions into `when_to_use`. |
| Structure | PASS | Decision content (gate, directions table, sufficiency criteria) all inline; no conditional loads. | None. |
| Over-prescription | PASS | One bolded hard rule (line 12) and one "This is critical" (line 76); no MUST/ALWAYS spam, no anti-laziness pushes. | Optional: soften "This is critical" (line 76). |
| Conciseness | WARN | A few lines restate things Claude already knows (coverage-report bullets, lines 63-65; "The failure message IS the documentation", line 44 duplicates lines 35-42). | Trim the coverage bullets and the redundant restatement. |
| Workflow completeness | PASS | Clear 5-step loop, explicit exit conditions ("When is the Safety Net Sufficient?", lines 92-97), and a failure path ("When the Code Resists Testing", lines 86-90). | None. |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance checklists, no "Red Flags — STOP" sections. | None. |
| Supply chain | PASS (N/A) | No bundled scripts, no agents, no network calls. | None. |
| Hygiene | PASS | No time-sensitive phrasing; consistent terminology; correctly references the `legacy-code-expert` agent by name; no README/CHANGELOG inside the skill. | None. |

## Findings

Ranked by severity.

### 1. (Low) No bundled evals
`validate_skill` reports `reference_files: 0` and there is no `evals/` directory. The skill-craft methodology treats ≥3 evals as a floor for any shipped skill, both to pin trigger behavior and to assert content quality. The trigger probe this session was degraded by infra errors, which is exactly the situation a committed eval set guards against.

**Fix:** add at least 3 evals — a positive (legacy code, no tests, wants safety net), a near-miss negative (existing test suite → expect routing to refactoring-guide), and a content eval asserting the response includes the "assertion you believe will fail → read the failure message → lock in actual value" loop and the no-bug-fixing rule.

### 2. (Low) Redundant restatement of the failure-message idea
Lines 35-44 establish "Let the failure message tell you the behavior" and then close with line 44:

> `The failure message IS the documentation.`

This caps a section that already made the point in lines 37 and 40-42. The all-caps "IS" is the only emphatic flourish in an otherwise calm document and adds tokens without adding instruction.

**Fix:** delete line 44, or fold its idea into the Step 3 heading.

### 3. (Low) Coverage section teaches what Claude already knows
Lines 61-67 explain what covered/uncovered/branch coverage mean:

> - **Covered lines**: you have a test that exercises this code
> - **Uncovered lines**: potential behavior you haven't captured yet
> - **Branch coverage**: conditional paths you haven't tested

These definitions are common knowledge; the load-bearing instruction is only the final sentence ("Use coverage to navigate to untested paths"). The bullets are recurring token cost on every load.

**Fix:** collapse to one line: "Run with coverage and use uncovered lines and branches to find behavior you haven't captured yet."

### 4. (Very low) "This is critical" intensifier
Line 76:

> `This is critical. Testing shallow-to-deep builds your understanding gradually...`

The sentence that follows already justifies the directions table; "This is critical" is an empty intensifier. Minor, but it is the one spot drifting toward over-emphasis.

**Fix:** drop "This is critical." and keep the explanatory sentence.

### 5. (Very low / observation) Exclusions live entirely in `description`
The eval metadata shows `when_to_use: null` — all routing (positive use + the two "Not for" exclusions) is packed into the single `description` field. This works (listing is 323 chars, untruncated) and triggered correctly. It is only an observation: moving the exclusion clause into a dedicated `when_to_use` field would separate "what it does" from "when to reach for it" and is the more idiomatic shape.

**Fix (optional):** split into `description` (capability) + `when_to_use` (triggers and exclusions).

## Recommendations

Prioritized:

1. **Add a committed eval set (≥3)** — highest value; the only methodology floor not met, and it would have de-risked this session's infra-flaky trigger probe. (Finding 1)
2. **Re-run `test_triggers` when the harness is healthy** to confirm the four negatives that returned `pass: null` (existing-test-suite, new-UserService, security-PR, flaky-debug) are correctly suppressed.
3. **Minor conciseness trims** — delete line 44, collapse the coverage bullets (lines 63-65), drop "This is critical." (line 76). Pure token savings, no behavior change. (Findings 2-4)
4. **Optional structural polish** — split exclusions into a `when_to_use` field. (Finding 5)

No remediation is blocking. The skill is shippable today; every item above is hardening or polish.
