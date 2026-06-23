# Skill Review: outside-in-tdd

**Summary:** A tight, well-scoped discipline skill for outside-in (London school) double-loop TDD that passes the validator clean and resists schedule pressure with a concrete, artifact-backed gate — overall verdict **PASS** with minor hygiene/over-prescription tweaks.

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` returned clean:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":123,"description_chars":187,"reference_files":0}}
```

- **Errors:** none.
- **Warnings:** none.
- **Manual cross-check:** name `outside-in-tdd` is lowercase+hyphens, ≤64 chars, matches the directory, and contains no `claude`/`anthropic` (line 2). Description is 187 chars, ≤1024, third person, no XML (line 3). SKILL.md is 123 lines, well under 500. No reference files exist, so the >100-line one-level-deep TOC rule is N/A (single file). **One real gap:** there are **0 eval files** in the directory (`reference_files:0`, and `find` shows only `SKILL.md`). The skill-craft floor expects ≥3 evals; none are bundled. The validator does not gate on this, but it is a deterministic-floor miss.

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` was run twice (10-query set, then a reduced 5-query set). **Both runs were infrastructure-blocked:** 25/25 then 10/10 runs returned `infra_errors` (Agent SDK / budget exhaustion — `total_cost_usd` 2.53 then 1.0 with zero completed sessions). Per the tool's own contract, infra errors are *not* counted as "did not trigger," so the `trigger_rate:0` values are **not real signal**. Only two negatives squeezed through cleanly in run 1 and both correctly stayed quiet:

- "Write characterization tests around this untested legacy class" → no trigger (`pass:true`) — correct (routes to characterization-testing).
- "Review this branch before I merge it" → no trigger (`pass:true`) — correct (routes to branch-review).

**Manual description analysis** (substitute for the blocked harness):

- **Should-trigger** queries are well covered by the description's concrete nouns: "vertical slice," "feature end-to-end," "outside-in (London school)," "double loop," "acceptance test outer loop," "classical TDD inner loop" (line 3). Phrasings like "controller down to the repository," "acceptance test first then build inward," and "London school double loop" map directly.
- **Near-miss exclusion** is the description's main weakness: it contains **no negative boundary clause**. Sibling skills (tdd-kata-coach, refactoring-guide, tpp-guide, characterization-testing) each explicitly disclaim outside-in-tdd in *their* descriptions, but this skill does not reciprocate. A self-contained kata ("practice the bowling game kata") shares the tokens "TDD / red green refactor," and "refactor this method, three strikes" shares "TDD / refactor" — both are plausible false positives that the description does nothing to deflect. This is the single highest-value fix.

**Recommendation:** re-run `test_triggers` when the SDK budget resets to get real numbers; treat the current probe as inconclusive.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | WARN | Validator clean (0 errors/warnings), but **0 evals bundled**; skill-craft floor wants ≥3 | Add ≥3 evals (pressure-test cases incl. the "we're late, skip the acceptance test" framing) |
| Triggers | WARN | No near-miss exclusion clause; kata/refactor/tpp queries can false-positive; harness probe inconclusive (infra-blocked) | Add a "Not for:" sentence pointing to tdd-kata-coach / refactoring-guide / characterization-testing; re-run probe |
| Structure | PASS | Gate stated inline at point of decision (line 12); failure modes co-located ("When Things Go Wrong", 94–98); facts not duplicated across sections | None |
| Over-prescription | PASS | Low imperative density for a discipline skill; one "do not skip"/"Gate" (line 12), no MUST/CRITICAL/ALWAYS shouting, no anti-laziness scolding | Optional: soften the numbered 6-step Process (54–92) which slightly over-specifies what Claude already knows |
| Conciseness | PASS | 123 lines, no padding; explains *its* method, not generic TDD; diagram earns its space | None |
| Workflow completeness | PASS | Explicit gate + artifact (line 12), per-phase exit conditions (45, 82), failure paths (96–98), "test passes immediately" handled | None |
| Banned constructs | PASS | No anti-rationalization table, no self-assessed-compliance checklist, no "Red Flags — STOP" block; tables are comparative/reference, not compliance theatre | None |
| Supply chain | PASS | No scripts, no executable assets, no network calls — nothing to audit | None |
| Hygiene | WARN | "Gate (do not skip)" phrasing leans on willpower vs. mechanism; minor terminology drift (`PARK` vs `park` vs `enter`) | Tie the gate to the artifact (already present) rather than an exhortation; normalize verbs |

## Findings

Ranked by severity.

### 1. (Medium) No near-miss exclusion in the description — false-positive risk against sibling skills
**Evidence (line 3):**
> `description: "Use when implementing a vertical slice or feature end-to-end using outside-in (London school) TDD with the double loop. Guides the acceptance test outer loop and classical TDD inner loop."`

The description is purely inclusive. The ecosystem has four close cousins — tdd-kata-coach (self-contained katas), refactoring-guide (refactor after green), tpp-guide (next transformation), characterization-testing (legacy safety net) — and *they* each name outside-in-tdd as the thing they are *not*. This skill should reciprocate so a "bowling kata" or "refactor this method" request does not pull it in on shared "TDD/refactor" tokens.

**Fix:** append a boundary sentence, e.g.:
> "Not for: a self-contained TDD kata or practice exercise (use tdd-kata-coach), refactoring after reaching green (use refactoring-guide), choosing the next transformation (use tpp-guide), or wrapping untested legacy code (use characterization-testing)."

That stays within the 1024-char limit (currently 187) and matches the house pattern used by every sibling.

### 2. (Medium) Deterministic floor: zero bundled evals
**Evidence:** `find` returns only `SKILL.md`; validator reports `reference_files:0`.

A discipline/process skill is exactly the kind that benefits from pressure-test evals, because its whole value is holding the line under "we're late." There are none. The validator doesn't fail on this, but the skill-craft floor expects ≥3.

**Fix:** add an `evals/` set with at least: (a) a happy-path vertical-slice request, (b) a near-miss kata that must route elsewhere, and (c) a **pressure case** — "the deadline is today, just write the implementation and we'll add the acceptance test after" — asserting the skill still demands the recorded failing acceptance run before inner-loop production code (the line 12 gate). This both documents and protects the gate.

### 3. (Low) Gate wording relies partly on exhortation rather than purely on mechanism
**Evidence (line 12):**
> "**Gate (do not skip):** ... No recorded failing run means no outer loop, regardless of schedule pressure."

The good news first: this gate is genuinely well-built — it is **artifact-backed** ("you can point to that recorded run output — the failure message and the failing assertion"), which is the right way to make a gate pressure-resistant rather than a willpower plea. The "do not skip" / "regardless of schedule pressure" framing is the weaker half: it edges toward the exhortation style the methodology discourages. The artifact requirement alone already enforces this; the scolding adds little.

**Fix (optional):** keep the artifact requirement verbatim, trim the exhortation to a single neutral clause, e.g. "Proceed only when you can point to the recorded failing run (failure message + failing assertion)." The "no artifact → no outer loop" logic does the enforcing.

### 4. (Low) Minor terminology / casing drift
**Evidence:** the diagram uses `PARK` (line 32) and `COMMIT`/`REFACTOR` in caps as phase labels, while prose uses lower-case "park," "commit," "refactor." Not confusing, but inconsistent.

**Fix:** pick one convention for phase verbs (caps in the diagram, sentence case in prose is fine as long as it's deliberate) — cosmetic only.

### 5. (Informational) Process section is slightly more granular than a frontier model needs
**Evidence (lines 56–92):** Step 1 spells out given/when/then mapping in 6 numbered sub-steps; Step 2 re-lists the classical RED-GREEN-REFACTOR-COMMIT-TRIANGULATE cycle that the model already knows and that tdd-kata-coach owns.

This is not over-prescription in the harmful sense (no MUST-density, no anti-laziness pushes), but it restates general TDD knowledge. The note that older skills tend to over-explain applies mildly here.

**Fix (optional):** compress Step 2 to a one-line pointer ("run the classical inner loop — see tdd-kata-coach for ZOMBIES ordering, baby steps, triangulation") to keep this skill focused on the *double-loop coordination* that is genuinely its own, and de-duplicate against tdd-kata-coach.

## Recommendations

Prioritized:

1. **Add a near-miss "Not for:" clause to the description** (Finding 1) — highest leverage, cheapest fix, directly improves trigger precision against four sibling skills.
2. **Bundle ≥3 evals including a schedule-pressure case** (Finding 2) — satisfies the skill-craft floor and locks in the gate's pressure-resistance, which is the skill's reason to exist.
3. **Re-run `test_triggers` once the SDK budget resets** — the current probe is infra-blocked and gives no real trigger signal; the manual analysis above is a stopgap, not a substitute.
4. **Trim the gate exhortation to lean on the artifact** (Finding 3) and **de-duplicate the inner-loop recap against tdd-kata-coach** (Finding 5) — optional polish; the skill is already in good shape.
5. **Normalize phase-verb casing** (Finding 4) — cosmetic.
