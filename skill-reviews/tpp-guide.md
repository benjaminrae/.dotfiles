# Skill Review: tpp-guide

A clean, concise, well-bounded TPP reference whose only serious defect is weak trigger recall — the description under-fires on natural "which transformation?" phrasings, including one that names TPP outright. **Overall verdict: WARN** (ships, but the description needs work before it reliably activates).

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` on the directory:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":68,"description_chars":307,"reference_files":0}}
```

- **0 errors, 0 warnings, 0 info.** Deterministic floor passes.
- `skill_md_lines: 68` — well under the 500-line limit; no TOC required (one bundled ref, SKILL.md < 100 lines).
- `description_chars: 307` — well inside 1024; `listing_chars: 307`, not truncated.
- Name `tpp-guide` is lowercase+hyphen, matches the directory, no `claude`/`anthropic`. Description (SKILL.md:3) is third person, no XML.
- **Anomaly (non-gating):** `reference_files: 0` despite `transformations-reference.md` existing on disk and being linked from SKILL.md:61 (`See \`transformations-reference.md\``). The validator does not count it as a registered reference file. The link resolves as plain prose, so this is informational, not an error — but worth confirming the file is intended/discoverable rather than orphaned.

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers`, 3 runs/query. The first pass carried 14 infra errors that polluted several verdicts, so I re-ran the ambiguous positives/negatives clean. Combined signal:

| Query | should_trigger | clean rate | verdict |
|---|---|---|---|
| "Which transformation should I pick to make this failing test pass with the simplest code change?" | yes | **0/3** | FAIL |
| "Apply the transformation priority premise to this prime factors step" | yes | **0/3** | FAIL |
| "My test passes with a constant. What's the next simplest transformation to generalize it?" | yes | **0/3** | FAIL |
| "evolve my code from a hard-coded constant... priority order of code transformations?" | yes | 3/3 | PASS |
| "Teach me TPP — choose between an if and a while when making a test go green?" | yes | 3/3 | PASS |
| "Help me order my test cases using ZOMBIES" | no | 0/3 | PASS (no over-trigger) |
| "reached green, help me refactor... remove duplication" | no | 0/3 | PASS (near-miss → refactoring-guide) |
| "full TDD kata with baby steps and commit discipline" | no | 0/3 | PASS (near-miss → tdd-kata-coach) |
| "What test should I write next using triangulation?" | no | 0/3 | PASS (near-miss → tdd-kata-coach) |
| "Implement... feature end to end with outside-in TDD" | no | 0/3 | PASS |

**Negatives are excellent — zero over-triggering on any near-miss.** The exclusion clause ("Not for... ZOMBIES... triangulation... commit discipline (use tdd-kata-coach)") does its job cleanly. This is a notable improvement over an earlier version of this skill.

**Positives are the problem.** The starkest miss: "Apply the transformation priority premise to this prime factors step" names the premise verbatim and names the worked example, yet triggers **0/3**. Generic "which transformation should I pick / what's the next transformation" phrasings also miss. The description only fires reliably when the literal "TPP" token or "priority order of transformations" appears. Recall on natural GREEN-step phrasings is the dominant weakness.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | PASS | 0 errors/0 warnings; only a `reference_files:0` curiosity | Confirm the ref file is registered/discoverable |
| Triggers | FAIL | 3/5 strong positives miss, incl. one naming TPP + the kata in the worked example; description leans on the literal "TPP" token | Lead with the user's decision + concrete nouns: "which transformation", "simplest code change to pass a test", "constant → scalar", "if vs while at green" |
| Structure | PASS | Point-of-decision guidance inline (SKILL.md:35-42); each fact in one place; ref linked directly (SKILL.md:61) | None |
| Over-prescription | PASS | No MUST/CRITICAL/ALWAYS density; explicitly hedges (line 31); tie-break says "either choice is fine" (line 40) | None |
| Conciseness | WARN | Full 14-row table duplicated across both files | Optionally drop the reference's trailing summary table |
| Workflow completeness | PASS | Clear GREEN-only scope gate (lines 44-49); priority ordering explicit; tie-break rule (line 40) | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance, no "Red Flags—STOP" | None |
| Supply chain | PASS | No scripts, no executables, no network calls | None |
| Hygiene | PASS | No time-sensitive phrasing, consistent terms, no README/CHANGELOG; MCP names N/A | None |

## Findings

### 1. (High) Trigger recall fails on natural "which transformation" phrasings — including one naming TPP

Evidence (clean probe): "Apply the transformation priority premise to this prime factors step" → **0/3**; "Which transformation should I pick to make this failing test pass with the simplest code change?" → **0/3**; "My test passes with a constant. What's the next simplest transformation to generalize it?" → **0/3**.

The description (SKILL.md:3) opens with the mechanism name — "teaching or applying the Transformation Priority Premise (TPP)" — rather than the user's concrete situation. A developer at a GREEN step rarely thinks "I want to apply TPP"; they think "what's the simplest change to pass this test?" The description contains none of the concrete nouns a user would actually type in that moment (no "which transformation", no "constant → scalar", no "if vs while").

Fix — lead with the decision, inject the situational vocabulary, keep TPP as the named mechanism:
> "Use when choosing the simplest code change to make a failing test pass during TDD — picking the next transformation (e.g. constant → scalar, if → while) to evolve code from specific to general at the RED→GREEN step. This is the Transformation Priority Premise (TPP). Not for overall kata flow, ZOMBIES ordering, baby steps, triangulation, or commit discipline (use tdd-kata-coach); not for refactoring after green (use refactoring-guide)."

This preserves the strong negative behavior while adding the missing positive surface. Re-run `test_triggers` after editing; consider `optimize_description` if a hand edit doesn't lift recall to ≥4/5.

### 2. (Low) Near-miss exclusion omits refactoring-guide

Evidence: the exclusion clause at SKILL.md:3 names only tdd-kata-coach. Yet the skill's own Scope section flags refactoring as a separate concern: SKILL.md:49 "REFACTOR (cleanup once green) is driven by refactoring discipline, not TPP." The probe shows the refactor query already stays quiet (0/3), so this is preventive hardening rather than a live defect — but naming refactoring-guide in the exclusion (as in the Finding 1 fix) makes the boundary explicit and future-proofs it.

### 3. (Low) `reference_files: 0` in validator stats despite a real, linked reference file

Evidence: validator `stats.reference_files: 0`; `transformations-reference.md` exists and is referenced at SKILL.md:61. Functionally harmless (the prose link resolves), but confirm the file is intended as a loadable reference and not orphaned dead weight.

### 4. (Low) Full 14-row transformation table duplicated across both files

Evidence: SKILL.md:14-29 ("The 14 Transformations") and transformations-reference.md:243-260 ("TPP Summary Table") restate the same 14 rows with near-identical descriptions (e.g. row 1 differs only in wording: "No code -> return null/0/empty" vs "Transform a function that isn't a function into one that returns null or 0"). Two sources of truth can drift. The reference's standalone walkthrough is valuable; its trailing summary table is the redundant part. Consider dropping transformations-reference.md:243-260 and letting SKILL.md own the canonical list.

## Recommendations

1. **(Do first) Rewrite the description** to lead with the GREEN-step decision and inject concrete trigger nouns ("which transformation", "simplest code change to pass a test", "constant → scalar", "if vs while"), keeping TPP as the named mechanism after the situation. Add refactoring-guide to the exclusion clause. Re-run `test_triggers`, target ≥4/5 positives with no negative regression; reach for `optimize_description` if needed.
2. **(Optional) Trim duplication:** remove the trailing summary table from transformations-reference.md (lines 243-260) so the 14-transformation list lives canonically in SKILL.md only.
3. **(Optional) Confirm the reference file registration** given the `reference_files: 0` stat.

Content quality is genuinely strong: accurate TPP ordering, an honest hedge that the lower-priority ordering (9-14) is "heuristic and contested in the literature — treat it as rough guidance, not a strict algorithm" (line 31), a clean GREEN-only scope gate (lines 44-49), a concrete tie-break rule (line 40), and a complete PrimeFactors worked example. The skill is free of the discipline-skill anti-patterns (no anti-rationalization tables, no self-graded checklists, no coercion blocks). It needs a description fix, not a content fix.
