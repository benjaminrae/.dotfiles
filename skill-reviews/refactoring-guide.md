# Skill Review: refactoring-guide

A clean, concise, well-gated discipline skill whose body is in good shape, but its description under-triggers on the "improve existing code structure" half it advertises, and it ships with zero evals. **Overall verdict: WARN** (revise-and-ship; no blocking spec errors, but trigger coverage and missing evals must be fixed before it can be trusted to fire).

## Validator output

`validate_skill` ran clean — **PASS, no errors, no warnings, no info findings**:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":106,"description_chars":171,"reference_files":0}}
```

- `name: refactoring-guide` (line 2) — lowercase, hyphenated, matches directory, ≤64 chars, no `claude`/`anthropic`. PASS.
- `description` 171 chars (line 3) — within 1–1024, third person, no XML. PASS.
- SKILL.md 106 lines — under the 500-line ceiling. PASS.
- `reference_files: 0` — single-file skill; no refs needed, no TOC required (only 106 lines).
- **Eval gap (methodology floor, not enforced by validator):** the skill bundles **0 evals**. The skill-craft floor expects ≥3. The validator does not gate on this, so it is reported here as a methodology FAIL rather than a spec error.

## Trigger probe

First run was corrupted by infrastructure: 23 of 30 runs returned infra errors, so the initial near-zero trigger rates were noise. A re-run at lower concurrency produced clean signal:

| Query | should_trigger | trigger_rate | Result |
|-------|----------------|--------------|--------|
| "I just got my tests green, time to clean up this code" | yes | 1.0 | PASS |
| "My tests pass now, refactor the implementation" | yes | 1.0 | PASS |
| "Can you help me improve the structure of this existing module?" | yes | **0.0** | **FAIL** |
| "This method is way too long, I want to extract some parts out" | yes | **0.0** | **FAIL** |
| "There's duplicated logic in three places here, what should I do?" | yes | **0.0** | **FAIL** |
| "Write a failing test for the login endpoint" | no | 0.0 | PASS |
| "I need characterization tests for untested legacy code" (run 1) | no | 0.0 | PASS |
| "Review this branch before I merge it" (run 1) | no | 0.0 | PASS |
| "What's the next test case for my kata?" (run 1) | no | 0.0 | PASS |

**Key finding:** the skill fires reliably when the user literally says "refactor" or "tests green," but **fails to fire on the implicit-improvement half of its own description.** The description (line 3) claims "or when improving existing code structure," yet "improve the structure of this existing module," "method is too long, extract some parts," and "duplicated logic in three places" — the literal three-strikes scenario the skill is built around — all triggered 0/3. Near-miss exclusions are solid (no false positives on new-feature TDD, characterization, branch review, or kata).

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | WARN | Spec clean, but 0 evals vs ≥3 expected | Add ≥3 evals asserting gate behaviour (refuse-on-red, revert-on-break) |
| Triggers | FAIL | 3/5 positive intents triggered 0.0; "improving existing code structure" half does not fire | Add concrete trigger nouns: "long method," "extract method," "duplicated code," "clean up after green" |
| Structure | PASS | Point-of-decision tables inline; gate stated where it applies | None |
| Over-prescription | WARN | `NEVER`×2, `REVERT immediately`, `<HARD-GATE>` + duplicated gate section; modest but redundant | Merge the duplicated gate statements; keep one authoritative gate |
| Conciseness | WARN | Restates refactoring fundamentals Claude already knows (Extract Method/Variable/Rename "When/How/Why") | Trim pattern definitions to the decision table; drop tutorial prose |
| Workflow completeness | PASS | Gate, three-strikes, revert path, and exit conditions all present | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed-compliance checklist, no "Red Flags — STOP" | None |
| Supply chain | PASS | No scripts, no executable bundles | None |
| Hygiene | PASS | No README/CHANGELOG, no time-sensitive phrasing, consistent terms; uses custom `<HARD-GATE>` tag | Optional: prefer plain heading over a non-standard XML-style tag |

## Findings

### 1. (HIGH) Description under-triggers on the "improving existing code structure" intent

The description (line 3): `"Use when refactoring code after reaching green in TDD, or when improving existing code structure. Enforces safety-first refactoring discipline with the three strikes rule."`

The probe shows the second clause is functionally dead. Three queries that are squarely "improving existing code structure" each triggered **0/3**:
- "Can you help me improve the structure of this existing module?"
- "This method is way too long, I want to extract some parts out"
- "There's duplicated logic in three places here, what should I do?"

The last is the exact scenario the skill's centrepiece (The Three Strikes Rule, lines 26–34) exists to handle, yet the skill never surfaces. The abstract phrase "improving existing code structure" lacks the concrete nouns Claude pattern-matches on.

**Fix:** rewrite the description to lead with the dominant use case and embed concrete triggers, e.g.:
`"Use after reaching green in TDD to clean up code, or when improving the structure of existing code — extracting a long method, renaming for clarity, removing duplicated logic. Enforces safety-first refactoring: only refactor on green, small steps, revert on break, and the three strikes rule before abstracting."`

### 2. (MEDIUM) Ships with zero evals

`reference_files: 0` and no eval block. A discipline skill's whole value is the gate; without evals there is no regression guard that the gate behaviour (refuse to refactor on red, revert on broken test, wait for the third occurrence) actually lands. Methodology floor is ≥3.

**Fix:** add at least three evals — (a) "tests are red, please refactor" → asserts the skill refuses/runs tests first; (b) "a refactor broke a test" → asserts revert-to-green; (c) "duplication appears twice" → asserts it does *not* abstract yet.

### 3. (LOW) Duplicated gate / over-prescription redundancy

The hard gate is stated three times: `<HARD-GATE>` (lines 12–14: "NEVER refactor when tests are RED… green confirmed by output, not by assumption"), Core Rules 1 + 4 + 6 (lines 18–24), and "The Gate After Every Change" (lines 88–90: "This is the only check that matters; it is observed in the test output, not self-assessed"). The content is good and the anti-self-assessment framing is correct, but the same rule restated in three voices adds tokens and risks drift. Discipline skills tend to over-prescribe; here the prescriptiveness is mild (`NEVER`×2, `REVERT immediately`) but redundant.

**Fix:** keep one authoritative gate (the `<HARD-GATE>` block is the strongest), and have Core Rules / "The Gate After Every Change" reference it rather than re-asserting it.

### 4. (LOW) Tutorial-grade restatement of refactoring fundamentals

The "Refactoring Patterns" section (lines 36–56) defines Extract Method, Rename, Extract Variable, and Simplify Conditional with When/How/Why prose — material Claude already knows well. The adjacent "Choosing a Pattern" decision table (lines 58–65) carries the actual decision value; the prose definitions above it are redundant.

**Fix:** collapse the four pattern subsections into the decision table (symptom → pattern), which is the point-of-decision content worth keeping. This also reclaims tokens for the gate and three-strikes guidance, which are the skill's differentiators.

### 5. (INFO) Non-standard `<HARD-GATE>` tag

Lines 12–14 use a custom XML-style `<HARD-GATE>...</HARD-GATE>` tag. The validator did not flag it and it reads clearly, but it is not a recognised construct; a plain bold heading conveys the same emphasis without inventing markup.

## Recommendations

Prioritized:

1. **Rewrite the description (Finding 1)** to embed concrete triggers ("long method," "extract," "duplicated code," "clean up after green") so the "improving existing code structure" intent actually fires. Re-run `test_triggers` to confirm the three currently-failing positives reach ≥0.5.
2. **Add ≥3 evals (Finding 2)** covering refuse-on-red, revert-on-break, and wait-for-third-occurrence.
3. **De-duplicate the gate (Finding 3)** — one authoritative statement, others reference it.
4. **Collapse pattern prose into the decision table (Finding 4)** to cut tutorial tokens.
5. **Optional:** replace `<HARD-GATE>` with a plain bold heading (Finding 5).

Structure, workflow completeness, banned-construct hygiene, and supply chain are all clean and need no work.
