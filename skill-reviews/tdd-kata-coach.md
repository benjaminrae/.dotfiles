# Skill Review: tdd-kata-coach

A disciplined, well-scoped single-file kata coach that passes the validator and trigger probes cleanly; the main issues are a non-standard `<HARD-GATE>` XML construct in the body and a redundant "Anti-Patterns to Flag" list that re-states facts already given inline. **Overall verdict: PASS with minor remediation.**

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` ran against the directory and returned a clean result:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":136,"description_chars":394,"reference_files":0}}
```

- **Errors:** none.
- **Warnings:** none.
- **Floor checks (cross-verified manually):**
  - name `tdd-kata-coach` — lowercase + hyphens, 14 chars, matches directory, no claude/anthropic. PASS.
  - description 394 chars (≤1024), third person, no XML in frontmatter. PASS.
  - SKILL.md 136 lines (<500). PASS, no TOC required.
  - reference files: 0 — single-file skill, no one-level-deep concern.
  - Evals: the validator does not flag missing evals here, and trigger evals were run live (below). No bundled eval set exists in the directory, which is an authoring gap but not a validator error.

Deterministic floor: **PASS.**

## Trigger probe

Ran `mcp__plugin_oberskills_skill-eval__test_triggers` (3 runs/query, haiku, claude_code preset). First pass had infra noise on three positives; those were re-run clean. Combined results:

**Should-trigger (5/5 pass):**
| Query | Trigger rate | Result |
|-------|--------------|--------|
| "practice the FizzBuzz kata with TDD, walk me through red-green-refactor" | 1.0 (2/2 valid) | PASS |
| "Coach me through the Roman Numerals kata using strict TDD baby steps" | 1.0 (2/2 valid) | PASS |
| "String Calculator kata, help me order test cases with ZOMBIES" | 1.0 (3/3) | PASS |
| "practice TDD on the Bowling Game exercise from scratch" | 1.0 (3/3) | PASS |
| "TDD kata for Prime Factors, one failing test at a time" | 1.0 (3/3) | PASS |

**Near-miss negatives (5/5 pass):**
| Query | Intended skill | Trigger rate | Result |
|-------|----------------|--------------|--------|
| "Implement the checkout feature end to end with acceptance tests and the double loop" | outside-in-tdd | 0.0 | PASS |
| "What is the next code transformation I should apply at this red-green step?" | tpp-guide | 0.0 | PASS |
| "My tests are green now, help me refactor this code safely" | refactoring-guide | 0.0 | PASS |
| "Review my pull request for code quality issues" | branch-review/code-review | 0.0 | PASS |
| "Add a logout button to the navbar of my React app" | (none) | 0.33 | PASS (below 0.5 threshold) |

Discrimination against the three sibling skills named in the `Not for:` clause is perfect (0.0 each). The lone non-zero negative (React feature, 0.33) stays under threshold and is benign — a one-off near-association with "TDD-shaped coding," not a structural leak. **Trigger probe: PASS.**

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | PASS | Clean — 0 errors, 0 warnings, 136 lines, 394-char description | None |
| Triggers | PASS | 10/10 positive, near-misses excluded; siblings 0.0 | None |
| Structure | WARN | "Anti-Patterns to Flag" (L99–107) duplicates facts already stated inline in the process steps | Cut the list or replace with a pointer; keep each fact in one place |
| Over-prescription | PASS | One HARD-GATE; MUST/NEVER/ALWAYS density is low and proportionate for a discipline skill | None |
| Conciseness | WARN | ZOMBIES table re-teaches a concept Claude knows; Test Organization (L92–97) is TS-specific dogma the kata flow does not need | Trim to the kata-specific decisions; drop generic explanation |
| Workflow completeness | PASS | RED→GREEN→REFACTOR gates, ZOMBIES ordering, triangulation, commit discipline, exit condition (L82) all present | None |
| Banned constructs | WARN | `<HARD-GATE>` XML-style tag (L12, L14); "Anti-Patterns to Flag" is a soft self-assessed-compliance checklist | Replace tag with a plain bold imperative; see Findings |
| Supply chain | PASS | No scripts, no executables, zero reference files | None |
| Hygiene | PASS | No time-sensitive phrasing, no README/CHANGELOG, terms consistent (ZOMBIES, triangulation, baby steps) | None |

## Findings

Ranked by severity.

### 1. (WARN) `<HARD-GATE>` is a non-standard XML construct in the body
**Evidence — L12–14:**
```
<HARD-GATE>
NEVER write production code without a failing test. If you catch yourself about to write implementation code, STOP and write the test first. This is non-negotiable.
</HARD-GATE>
```
House rules discourage XML-style pseudo-tags in skill bodies; they read as machine directives and add no parsing value over markdown. The content itself is correct and appropriately the single hard gate for a TDD discipline skill — the wrapper is the problem, not the rule. The "If you catch yourself… STOP" phrasing is also mild anti-laziness scaffolding written for weaker models; on a current model a plain imperative suffices.
**Fix:** Replace with a plain emphasized line, e.g. a blockquote `> **Hard gate:** Never write production code without a failing test — write the test first.` Drop the self-monitoring "if you catch yourself" clause.

### 2. (WARN) "Anti-Patterns to Flag" duplicates inline facts (each fact in two places)
**Evidence — L99–107** lists seven items that already appear as positive rules in the process:
- "Writing production code before the test" = the HARD-GATE (L13).
- "Committing while tests are red" = GREEN step 5 "COMMIT — we are in green" (L57) and the When-stuck gate (L90).
- "Skipping the refactoring step" / "Adding comments instead of improving naming" / "Making large leaps instead of baby steps" all restate REFACTOR (L59–70) and the Overview (L10).

This is a maintenance hazard (edit one, forget the other) and pure token cost. It also reads as a self-assessed compliance checklist rather than actionable guidance.
**Fix:** Delete the section. If a consolidated "smells" reminder is wanted, keep only items NOT stated elsewhere (there are none today), or fold a one-line pointer into the When-stuck section.

### 3. (WARN) Conciseness — re-teaching ZOMBIES and generic test-org dogma
**Evidence — ZOMBIES table L22–30** spells out each letter ("Z | Zero | Empty case, null, zero, nothing"). A current model knows ZOMBIES; the table earns its keep only as a *checklist to confirm ordering*, not as a lesson. **Test Organization L92–97** prescribes `.spec.ts` suffix and "manual test doubles over framework mocks" — TypeScript/project-specific dogma that is unrelated to running a kata cycle and will be wrong for a Java or Python kata.
**Fix:** Keep the ZOMBIES letters as a terse ordered list (no Description column), and either drop Test Organization or reduce it to one language-agnostic line ("test behavior, not implementation").

### 4. (INFO) No bundled eval set
The directory contains only SKILL.md (`reference_files: 0`). Trigger evals had to be supplied ad hoc for this review. Per skill-craft, a discipline skill benefits from a committed eval set so regressions are caught. Live probes here passed 10/10, so this is an authoring gap, not a defect.
**Fix (optional):** Add an `evals/` set with the should/shouldn't queries used above.

### 5. (INFO) Example uses TypeScript-specific syntax
**Evidence — L45** `throw new Error('Method not implemented')` and L94 `.spec.ts`. The skill claims general applicability ("a coding kata," L10) but its concrete guidance is TS-flavored. Acceptable as an illustrative example, but worth a one-word "(language-specific example)" note so it is not read as mandatory.

## Recommendations

Prioritized:

1. **Replace the `<HARD-GATE>` XML tag** (L12–14) with a markdown blockquote and drop the "if you catch yourself" self-monitoring clause. Removes the one banned construct.
2. **Delete "Anti-Patterns to Flag"** (L99–107). It duplicates inline rules — fixes both the Structure and Banned-constructs warnings and cuts tokens.
3. **Slim the ZOMBIES table to a terse list and trim Test Organization** to language-agnostic guidance (or remove). Conciseness and portability.
4. **(Optional)** Commit the trigger eval set used here so the strong sibling-discrimination is regression-protected.
5. **(Optional)** Mark the TS snippets as illustrative examples to reinforce language-agnostic intent.

No changes affect triggering or workflow correctness — all five remediations are wording/structure cleanups. The skill is shippable as-is; the edits raise it from solid to clean.
