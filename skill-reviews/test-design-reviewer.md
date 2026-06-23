# Skill Review: test-design-reviewer

A well-researched test-quality knowledge base that is **broken as a skill**: there is no `SKILL.md`, so the validator and trigger harness both hard-fail, and the entry-point document (`farley-properties-and-scoring.md:9`) delegates all math to `lib/cli_calculator.py`, which does not exist in this directory. **Overall verdict: FAIL** (deterministic floor) — the directory is the reference payload for the `test-design-reviewer` *agent* (`claude/.claude/agents/test-design-reviewer.md`), not a self-contained skill, and is unusable through the skill surface.

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` on `/Users/benjamin.rae/cowork/dev/.dotfiles/claude/.claude/skills/test-design-reviewer`:

```json
{"valid":false,
 "errors":[{"rule":"skill-md-missing","message":"no SKILL.md in the skill directory","file":"SKILL.md"}],
 "warnings":[],"info":[],
 "stats":{"skill_md_lines":0,"description_chars":0,"reference_files":0}}
```

**ERROR — `skill-md-missing` at `SKILL.md` (file absent).** This is a fatal floor failure. The directory contains only two reference files:

- `farley-properties-and-scoring.md` (225 lines, has `description:` frontmatter)
- `signal-detection-patterns.md` (410 lines, has `description:` frontmatter)

Both carry `name:`/`description:` frontmatter (e.g. `farley-properties-and-scoring.md:2-3`), which is the *skill listing* shape, yet neither is named `SKILL.md`. The validator cannot find an entry point, so it cannot read a description, count references, or check length. Everything downstream is blocked.

Context: this directory is referenced by the agent definition at `claude/.claude/agents/test-design-reviewer.md:7-9`:

```
skills:
  - farley-properties-and-scoring
  - signal-detection-patterns
```

So these files function as agent-loaded reference docs. As a *skill* (the artifact this review targets), it does not validate.

Manual floor checks on the agent's own listing surface (`agents/test-design-reviewer.md:2-3`), since that is what actually surfaces:
- name `test-design-reviewer` — lowercase+hyphen, ≤64 chars, matches dir, no `claude`/`anthropic`. PASS.
- description — third person, single sentence, 218 chars, no XML. PASS.
- The two reference files are 225 and 410 lines; `signal-detection-patterns.md` (410 lines) is large but has section structure (it is loaded on demand by the agent, not a SKILL.md body, so the <500-line SKILL rule does not bind it). It lacks a table of contents despite being >100 lines.

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` could not run:

```
test_triggers failed: ENOENT: no such file or directory, open
'.../skills/test-design-reviewer/SKILL.md'
```

The harness requires `SKILL.md` to build the temporary plugin listing, so the missing-floor failure cascades — trigger quality cannot be measured automatically. Manual assessment of the agent description (`agents/test-design-reviewer.md:3`), which is the real trigger surface:

> "Use for evaluating test code quality using Dave Farley's 8 Properties of Good Tests. Produces a Farley Index score (0-10) with per-property breakdown, signal evidence, worst offenders, and improvement recommendations."

Manual 10-prompt probe (5 should-trigger / 5 near-miss):

| # | Prompt | Expected | Predicted | Reasoning |
|---|---|---|---|---|
| 1 | "Review the test design quality of my JUnit suite" | trigger | trigger | "test design quality" is verbatim in the key use case |
| 2 | "Evaluate my tests against Dave Farley's properties" | trigger | trigger | named methodology present |
| 3 | "Score how healthy my test suite is" | trigger | likely | "evaluating test code quality" covers it, though "Farley" framing may dampen |
| 4 | "Find mock tautologies / tautology theatre in my tests" | trigger | weak | the most distinctive capability is **absent from the description** — only in reference bodies |
| 5 | "Give me a Farley Index for these tests" | trigger | trigger | "Farley Index" named explicitly |
| 6 | "Review this PR for correctness bugs" | no | no | description is scoped to test *design*, not bug-finding |
| 7 | "Write new unit tests for UserService" | no | no | no authoring language; near-miss correctly excluded by absence |
| 8 | "Refactor this function" | no | no | unrelated |
| 9 | "Do a general code review of my changes" | no | risk | "evaluating … code quality" could over-trigger; no explicit "test code only / not general review" exclusion |
| 10 | "Check my code coverage % and CI health" | no | no | the agent body excludes this (`agents/...:278`), but the *description* does not state it |

Net: the description triggers well on the named-methodology path but (a) buries its most differentiated hook — tautology-theatre detection — and (b) lacks any explicit near-miss exclusion ("not for general code review, writing new tests, or coverage/CI"), creating over-trigger risk against general-code-review requests.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | **FAIL** | No `SKILL.md`; validator returns `skill-md-missing` error; `reference_files:0`, `description_chars:0` | Add a `SKILL.md` entry point (or remove the dir from the skill surface and treat it purely as agent reference) |
| Triggers | **WARN** | Distinctive capability (tautology theatre) absent from description; no near-miss exclusion clause; over-trigger risk vs "general code review" | Add a near-miss exclusion; surface "mock tautology / tautology theatre" in the description |
| Structure | **WARN** | Entry doc points to `lib/cli_calculator.py` that is not in this dir; refs cross-reference each other as "skill"; 410-line ref lacks TOC | Bundle or fix the script path; add TOC to the long reference; call siblings "reference", not "skill" |
| Over-prescription | **PASS** | Zero `MUST`/`ALWAYS`/`NEVER`/`CRITICAL` in the reference files; tone is descriptive | None |
| Conciseness | **PASS** | Content is reference material Claude does not already know (specific regexes, weights, rubrics); justified token cost | Minor: trim duplicated tautology-theatre prose repeated across both files |
| Workflow completeness | **PASS** | Agent body has explicit gates per phase, exact formula, blend ratio, rating scale, exit conditions (`agents/...:35-76`) | None (lives in agent, not skill files) |
| Banned constructs | **PASS** | No anti-rationalization tables, no "Red Flags / STOP", no self-assessed-compliance gimmicks | None |
| Supply chain | **WARN** | Skill *claims* to delegate math to a bundled Python CLI but ships **no script**; the referenced `cli_calculator.py` exists only in the unrelated `cognitive-load-analyzer` skill | Either bundle the script in this dir (pinned/local, role stated) or rewrite the doc to describe in-context arithmetic |
| Hygiene | **WARN** | Time-sensitive "as of 2026" claim; inconsistent "skill" vs file naming; broken `lib/` reference; no README/CHANGELOG/`__pycache__` (good) | Drop or soften the "as of 2026" claim; fix terminology and the dangling path |

## Findings (ranked by severity)

### 1. FAIL — No `SKILL.md`; the skill does not exist as a skill
Validator: `{"rule":"skill-md-missing","file":"SKILL.md"}`. The directory holds two `*.md` reference files but no entry point. Consequences: `validate_skill` errors, `test_triggers` cannot run (`ENOENT … SKILL.md`), and nothing is discoverable via the skill mechanism. The capability is only reachable through the `test-design-reviewer` *agent* (`agents/test-design-reviewer.md:7-9`).
**Fix:** Decide the intent. If this is meant to be a usable skill, add a `SKILL.md` with proper frontmatter that points to these two files as references. If it is purely agent payload, it is fine where it sits but should not be presented as a skill — and the two files should not carry skill-style `name:`/`description:` frontmatter that mimics a listing surface.

### 2. WARN (high) — Broken / dangling script dependency claimed as deterministic core
`farley-properties-and-scoring.md:9`:
> "The Farley Index formula and sigmoid normalization are implemented in `lib/cli_calculator.py`. The agent delegates all math to this deterministic Python CLI calculator (JSON in, JSON out) to ensure reproducible scores."

There is no `lib/` directory and no `cli_calculator.py` in this skill (`find` confirms the only match is `skills/cognitive-load-analyzer/lib/cli_calculator.py`, a different skill). The reproducibility guarantee — the entire "deterministic floor" of the methodology — rests on a file that is not bundled here. Either the script was meant to be copied in and was forgotten, or the doc was lifted from another skill. This is the supply-chain finding inverted: the risk is not a malicious bundled script but a **missing** one that the methodology depends on. (No network calls, no obfuscation, no unpinned deps — because there is no script at all.)
**Fix:** Bundle `cli_calculator.py` into this skill's `lib/` (local, no network, deps pinned, role stated in a header comment), or rewrite `farley-properties-and-scoring.md:9` and the agent's Phase 3 to describe the arithmetic Claude performs in-context, dropping the false "delegates all math to this CLI" claim.

### 3. WARN — Time-sensitive claim will rot
`signal-detection-patterns.md:147`:
> "No mainstream static analysis tool (SonarQube, PMD, ESLint, tsDetect, testsmells.org) has rules for these patterns **as of 2026**."

Dated absolute claims silently become wrong. The point (these mock anti-patterns are not caught by common linters, so the LLM pass matters) survives without the date.
**Fix:** Replace with "are not reliably caught by mainstream static-analysis tools," dropping the year.

### 4. WARN — Inconsistent terminology: reference files call each other "skill"
`farley-properties-and-scoring.md:157` ("see `signal-detection-patterns` **skill**") and `:165` reference the sibling file as a "skill," and the agent body does likewise (`agents/...:31,44,63`). These are reference documents loaded by an agent, not independent skills. The conflation is what makes a reader expect a `SKILL.md` and find none.
**Fix:** Use "reference" / "the signal-detection-patterns reference" consistently, and reserve "skill" for an actual `SKILL.md`-backed artifact.

### 5. WARN — Long reference lacks a table of contents
`signal-detection-patterns.md` is 410 lines covering 5 languages × 4 anti-pattern classes plus per-property tables. A reference this size should expose a one-level TOC so the agent can jump to the relevant language section without loading the whole thing.
**Fix:** Add a short anchored TOC at the top (per-property tables, tautology theatre, mock anti-patterns AP1-AP4, language sections, detection priorities).

### 6. PASS-with-note — Content quality is genuinely strong
The rubrics (`farley-properties-and-scoring.md:51-153`), the explicit weight rationale with cross-framework citations (`:36-49`), the blend formula and reproducibility protocol (`:170-180`), and the language-specific regex tables (`signal-detection-patterns.md:259-376`) are detailed, non-obvious, and worth their token cost — this is real knowledge Claude does not carry by default. The tautology-theatre false-positive mitigation (`signal-detection-patterns.md:169,190`) shows careful design. None of it is over-prescriptive (zero `MUST`/`ALWAYS`/`CRITICAL`/`NEVER`), and there are no banned anti-rationalization or "Red Flags / STOP" constructs. The weakness is purely packaging, not substance.

### 7. Minor — Duplicated prose across the two files
The four tautology-theatre definitions and the "would this test pass if all production code were deleted?" framing appear in full in both `farley-properties-and-scoring.md:110-115` and `signal-detection-patterns.md:106-121` (and again in the agent body `:47-51`). "Each fact in one place" is mildly violated; drift risk if one copy is edited.
**Fix:** Keep the canonical definitions in `signal-detection-patterns.md` (the detection reference) and have the scoring file link to it rather than restate.

## Recommendations (prioritized)

1. **Resolve the floor (blocking).** Add a `SKILL.md` if this is intended to be a skill; otherwise stop presenting the directory as one and strip the skill-style frontmatter from the two reference files. Nothing else matters until `validate_skill` passes.
2. **Fix the missing script (high).** Bundle `lib/cli_calculator.py` here (local, pinned, role-commented) or rewrite the "delegates all math to this CLI" claim at `farley-properties-and-scoring.md:9` to match reality. The reproducibility story is currently fiction.
3. **Harden the trigger surface.** Surface "mock tautology / tautology theatre" in the description and add an explicit near-miss exclusion ("not for general code review, writing new tests, or coverage/CI health") to curb over-trigger against general code-review prompts. Re-run `test_triggers` once `SKILL.md` exists.
4. **Hygiene pass.** Remove "as of 2026" (`signal-detection-patterns.md:147`); normalize "skill" → "reference"; add a TOC to the 410-line file; de-duplicate the tautology-theatre definitions to a single canonical location.
