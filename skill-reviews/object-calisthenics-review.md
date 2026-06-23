# Skill Review: object-calisthenics-review

**Summary:** A clean, well-scoped reference skill that passes the validator with zero errors/warnings, but the trigger probe shows it fails to fire even on its canonical key use case ("Review this class for Object Calisthenics violations" → 0/3 clean runs), making the description the one blocking defect. **Overall verdict: WARN (content is sound; triggering is broken).**

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` on the directory returned:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":129,"description_chars":468,"reference_files":0}}
```

- **Errors:** none → deterministic floor PASS.
- **Warnings:** none.
- Manual cross-check of floor items: name `object-calisthenics-review` is ≤64 chars, lowercase + hyphens, matches the directory, contains no `claude`/`anthropic`. Description is 468 chars (≤1024), third person ("Evaluates code…"), no XML. SKILL.md is 129 lines (<500). There are zero reference files, so the "refs one level deep / TOC if >100 lines" rule is N/A. **No bundled evals exist** — the "≥3 evals" expectation is unmet (see Findings F3).

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` was run in isolation (candidate skill wrapped in a temporary plugin; a trigger = an actual Skill tool_use). Several runs hit infrastructure errors (budget/infra), reported separately and not counted as "did not trigger." Aggregated across the three probe batches, the **clean** (infra-free) results were:

| Query | Should trigger | Clean runs | Triggered | Pass |
|---|---|---|---|---|
| "Review this class for Object Calisthenics violations" | yes | 3 | 0 | **FAIL** |
| "Check my code against the 9 object calisthenics rules" | yes | 2 | 0 | **FAIL** |
| "I'm doing a kata and want to apply object calisthenics as a design constraint" | yes | 1 | 0 | **FAIL** |
| "Does this code follow good OO design? Look at Demeter and primitive obsession" | yes | 2 | 0 | **FAIL** |
| "Review this PR for correctness bugs and security issues" (near-miss) | no | 2 | 0 | PASS |
| "I just reached green, help me refactor this code safely" (near-miss) | no | 2 | 0 | PASS |
| "Plan what to test for this feature branch before merging" (near-miss) | no | 3 | 0 | PASS |
| "Fix the failing test in my checkout module" (near-miss) | no | 1 | 0 | PASS |
| "Write me a JPA entity for an Order with a shipping address" (near-miss) | no | 3 | 0 | PASS |

**Interpretation:** Precision is excellent — every near-miss (general correctness/security review, post-green refactoring, branch/PR QA, bugfix, JPA authoring) correctly stayed quiet. But **recall is broken**: even the most explicit, on-the-nose request naming the skill by title does not invoke it. Because the probe runs the skill in isolation, this is not loss to a competing sibling — the listing surface itself is not persuading the model to fire. This is the dominant issue in the review.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | PASS | 0 errors, 0 warnings, 129 lines, desc 468 chars | None |
| Triggers | FAIL | Key use case fails to fire (0/3 clean on the canonical query); 4/4 clean positives missed | Lead the description with an imperative use-case verb + trigger phrases; see F1 |
| Structure | PASS | Detect/Fix inline at each rule; finding format + worked example co-located; each fact in one place | None |
| Over-prescription | PASS | No MUST/CRITICAL/ALWAYS density; thresholds hedged ("~50 lines", "rough thresholds — adjust"); no anti-laziness scolding | None |
| Conciseness | WARN | Re-explains the 9 OC rules and their rationale (Rules 1–4, 9 carry "Why" prose) the model already knows | Trim "Why" bullets to the detect/fix deltas; see F4 |
| Workflow completeness | PASS | Standardized finding block (L111-116), severity scale (L104-107), worked example (L120-125), ordering rule (L101) | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance checklist, no "Red Flags / STOP" | None |
| Supply chain | PASS | No scripts, no executables, zero bundled files | None |
| Hygiene | PASS | No time-sensitive phrasing; terms consistent; no README/CHANGELOG; no MCP names referenced | None |

## Findings (ranked by severity)

### F1 — CRITICAL: the skill does not trigger on its own key use case
Trigger probe, isolated: `"Review this class for Object Calisthenics violations"` → **0 triggers / 3 clean runs**; `"Check my code against the 9 object calisthenics rules"` → **0 / 2 clean**. Two more indirect positives (kata-as-constraint; "good OO design / Demeter / primitive obsession") also missed.

The description opens with **"Evaluates code against all 9 Object Calisthenics rules…"** (SKILL.md:3). It reads as a capability statement, not an instruction to act. The strong, well-written exclusion clause ("Not for: …") may also be over-suppressing: the model sees three "use X instead" redirections and concludes some other skill is the better fit even when the request is squarely in scope.

**Fix:** Rewrite the description to lead with the action and the literal trigger phrases users type. For example:
> "Use when reviewing code for Object Calisthenics violations or applying the 9 rules as a kata design constraint — flags one-level-of-indentation, no-else, primitive/collection wrapping, one-dot-per-line (Law of Demeter), no-getters and the other rules, with a standardized finding format. Trigger on 'object calisthenics', 'check the 9 OO rules', 'review OO design quality'. Not for general correctness/security review (code-reviewer), post-green refactoring (refactoring-guide), or branch/PR QA (qa-report)."

Keep the key use case first, keep concrete nouns, but make sure the positive trigger surface is heavier than the exclusion surface. **Re-run `test_triggers` after the change — this finding gates shipping.**

### F2 — MEDIUM: severity scale embeds rule-number assumptions that can mislead
SKILL.md:105-107 hard-codes severity-to-rule mappings: "High — … (Rules 5, 9; Rules 3/4 … in public APIs)", "Medium — … (Rules 7, 8; Rules 1, 2 …)", "Low — … (Rule 6…)". This is a reasonable default, but stated this rigidly it invites mechanical severity assignment regardless of blast radius (a Rule 6 abbreviation on a public API symbol can matter more than a Rule 1 nesting in a throwaway helper). Minor, since L102 already says "not every rule applies in every context."

**Fix:** Reframe as "typical severity (adjust to blast radius)" so the mapping reads as a prior, not a lookup table.

### F3 — MEDIUM: no bundled evals
The directory contains only `SKILL.md` (validator reports `reference_files:0`; `find` shows a single file). The skill-craft floor expects ≥3 evals so triggering and output quality are regression-checked. Their absence is exactly why F1 went undetected before this audit.

**Fix:** Add an evals set (positive triggers incl. the canonical query, the near-miss negatives used above, and at least one output-quality eval that feeds a small class with known violations and asserts the finding-block format from L111-116).

### F4 — LOW: "Why" prose re-explains what the model already knows
Rules 1–4 and 9 carry multi-bullet "Why" sections (e.g., L36-39 on primitive obsession, L90-93 on Tell-Don't-Ask) explaining concepts the model already holds. Rules 5–8 (L62-86) are the strongest sections precisely because they cut to **Detect/Fix** with a discriminating test (e.g., the fluent-vs-navigation test at L68). The educational tone in the earlier rules costs tokens without changing behavior.

**Fix:** Normalize all 9 rules to the Rule 5–8 shape: one-line intent + **Detect** + **Fix**. Drop the rationale bullets or compress each to a single clause.

### F5 — LOW: inconsistent rule sub-structure
Rules 1–4 and 9 use "Why / How to fix / Rules"; Rules 5–8 use "Detect / Fix / Note." The mixed templates make the document harder to scan and signal that the rules were written at different times.

**Fix:** Adopt one template across all 9 (the Detect/Fix shape is the better one).

## Recommendations (prioritized)

1. **(Blocking) Fix F1** — rewrite the description to lead with an action verb and literal trigger phrases, and lighten the exclusion clause so it does not out-weigh the positive surface. Re-run `test_triggers`; require the canonical query to pass before shipping.
2. **(High) Fix F3** — add ≥3 evals (positive triggers + the near-miss negatives + one output-format eval) so F1-class regressions are caught automatically.
3. **(Medium) Fix F2** — soften the severity-to-rule mapping to a "typical, adjust for blast radius" prior.
4. **(Low) Fix F4 / F5** — normalize all 9 rules to the Detect/Fix template used by Rules 5–8 and trim the "Why" prose; reclaims tokens and improves scannability.
