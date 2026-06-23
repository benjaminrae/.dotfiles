# Skill Review: cognitive-load-analyzer

**Summary:** This artifact is an *agent* (subagent definition), not a skill — the directory `skills/cognitive-load-analyzer/` contains no `SKILL.md`; the entry point lives at `claude/.claude/agents/cognitive-load-analyzer.md`, and the skill directory holds only two reference `.md` files plus a clean, well-engineered pure-stdlib Python `lib/`. **Overall verdict: FAIL** as a skill (no `SKILL.md`, so the validator and trigger harness cannot run); the underlying *content* is strong and the supply chain is clean, so the fix is structural (package it correctly), not a rewrite.

---

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` on the skill directory:

```json
{"valid":false,
 "errors":[{"rule":"skill-md-missing","message":"no SKILL.md in the skill directory","file":"SKILL.md"}],
 "warnings":[],"info":[],
 "stats":{"skill_md_lines":0,"description_chars":0,"reference_files":0}}
```

- **ERROR — `skill-md-missing`**: there is no `SKILL.md`. The directory is referenced as a "skill" by the agent's frontmatter (`agents/cognitive-load-analyzer.md:7-9`, `skills: [cli-dimensions-and-formulas, cli-tool-commands]`) but it is structured as an agent + bundled references, not a skill. Per the method, **any ERROR → verdict is FAIL until fixed.**

Because validation cannot proceed, the deterministic floor is unmet. Manual structural observations:
- The two reference files each carry their own `name`/`description` frontmatter (`cli-dimensions-and-formulas.md:1-4`, `cli-tool-commands.md:1-4`), i.e. they are authored as standalone mini-skills loaded by name. Neither has a SKILL.md, so neither is independently loadable as a skill by the spec.
- `cli-tool-commands.md` is **277 lines** and `cli-dimensions-and-formulas.md` is **232 lines** — both exceed the 100-line threshold that requires a table of contents, and **neither has a TOC**.
- The agent body (`agents/cognitive-load-analyzer.md`) is 188 lines — within the <500 line guide.
- No `name` field contains "claude"/"anthropic"; names are lowercase-hyphenated and match their file stems.

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` could not run — it also requires `SKILL.md`:

```
test_triggers failed: ENOENT: no such file or directory,
open '.../cognitive-load-analyzer/SKILL.md'
```

**Manual probe** of the agent's trigger surface (`agents/cognitive-load-analyzer.md:3`):
> "Use for calculating a Cognitive Load Index (CLI) score (0-1000) for a codebase. Measures 8 dimensions of cognitive load using static analysis and LLM-based naming assessment, producing a scored report..."

Should-trigger (all judged likely-trigger — concrete domain nouns "Cognitive Load Index", "score", "codebase"):
1. "What's the cognitive load of this codebase?" → trigger
2. "Calculate a cognitive load index score for src/" → trigger
3. "How hard is this code to understand? Give me a score" → trigger (weaker; no shared noun, relies on intent)
4. "Measure how mentally demanding this repo is to read" → trigger (weaker)
5. "Score the maintainability complexity across dimensions" → trigger

Should-NOT-trigger (near-misses):
6. "Review this branch before I merge it" → no (branch-review territory)
7. "Refactor this function to reduce nesting" → no
8. "Run the test suite" → no
9. "What does this function do?" → no
10. "Check for security vulnerabilities" → no

The description reads well and would trigger correctly, **but it has no near-miss exclusion clause** (no "Not for…"). Given sibling skills cover overlapping ground (refactoring-guide, object-calisthenics-review, branch-review, code-review), the risk of mis-triggering on "reduce complexity / improve maintainability" requests is real and untested. The description is also written agent-style ("You are a Cognitive Load Analyst…" at line 15) rather than skill-style; the third-person summary at line 3 is fine, but it is an *agent description*, not validated against the skill trigger harness.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | **FAIL** | No `SKILL.md`; validator errors `skill-md-missing`; harness can't run. | Add a `SKILL.md` (convert agent, or relocate references under a real skill). |
| Triggers | **WARN** | Good nouns and key-use-case-first, but no near-miss exclusion clause; never tested (harness blocked). | Add "Not for: general refactoring (use refactoring-guide), OO design scoring (use object-calisthenics-review), or branch QA (use branch-review)." |
| Structure | **WARN** | Two reference files >100 lines with no TOC; facts duplicated between spec doc and `lib/` (see Findings). | Add TOCs; make `lib/` the single source of formula truth and have the doc point to it. |
| Over-prescription | **PASS** | "Critical Rules" (5) and "Core Principles" (7) are calibrated and methodology-specific, not anti-laziness padding. No "show your thinking", no prefill, no MUST/ALWAYS spam. | None. |
| Conciseness | **PASS** | Tight, structured, example-driven. Minor: principles restate facts also in the doc. | Optional dedup. |
| Workflow completeness | **PASS** | Three phases each with an explicit **Gate** (lines 41, 51, 58); subagent-mode exit via `{CLARIFICATION_NEEDED}`; fallback path defined. | None. |
| Banned constructs | **PASS** | No anti-rationalization tables, no self-assessed compliance checklist, no "Red Flags — STOP". | None. |
| Supply chain | **PASS** | Pure stdlib (`math`, `hashlib`, `json`, `sys`, `warnings`, `pathlib`, `collections`); **no** network/subprocess/eval/exec/`os.system`; no encoded payloads; deterministic; runs clean. | Add a one-line "executed via Bash; no third-party deps" note (already mostly stated). |
| Hygiene | **WARN** | `lib/__pycache__/` present on disk and **untracked but not git-ignored** (visible in session `git status`); `#!/usr/bin/env python3` shebang sits on line 2 *after* a comment (inert); fully-qualified script paths are good. | Add `__pycache__/` and `*.pyc` to `.gitignore`; move shebang to line 1 or drop it. |

## Findings (ranked by severity)

### 1. (Blocker) No `SKILL.md` — this is an agent, not a skill
The review target `skills/cognitive-load-analyzer/` has no `SKILL.md`. The actual prompt is an agent at `agents/cognitive-load-analyzer.md`:
```
1  ---
2  name: cognitive-load-analyzer
4  model: sonnet
5  tools: Read, Bash, Glob, Grep
6  maxTurns: 30
7  skills:
8    - cli-dimensions-and-formulas
9    - cli-tool-commands
```
`model`, `tools`, `maxTurns` are agent-frontmatter fields, not skill fields. Consequences: the deterministic validator fails (`skill-md-missing`) and the trigger harness `ENOENT`s — **no automated quality floor can be established.** The two `skills:` entries point at the reference `.md` files, which are themselves frontmatter-bearing docs with no `SKILL.md` of their own, so they are not loadable as spec-compliant skills either.
**Fix (pick one):**
- If it is meant to be an agent, move/keep it under `agents/` and stop calling the directory a "skill"; reference `lib/` and the docs by path from the agent body (it already does, e.g. `agents/cognitive-load-analyzer.md:28,48,53`).
- If it is meant to be a skill, add `skills/cognitive-load-analyzer/SKILL.md` with proper frontmatter (`name`, `description`, optional `when_to_use`) and fold the agent body into it; demote the two reference docs to plain references (drop their `name`/`description` frontmatter or give each its own SKILL.md).

### 2. (High) Reference files exceed 100 lines with no table of contents
`cli-dimensions-and-formulas.md` (232 lines) and `cli-tool-commands.md` (277 lines) are both long, scannable reference docs but neither opens with a TOC, so an agent loading them pays full token cost to find one dimension's formula.
**Fix:** prepend a TOC (D1–D8 + Aggregation + Sampling) to each. Better, gate sections so only the needed dimension is read.

### 3. (Medium) Formula facts duplicated between the spec doc and `lib/`
Every sigmoid midpoint/steepness and weight appears twice: in `cli-dimensions-and-formulas.md` (e.g. `D1 = sigmoid(D1_raw, midpoint=15, steepness=0.15)`, line 45) and in `lib/dimensions.py` (`sigmoid(raw, midpoint=15, steepness=0.15)`, line 28). The doc even says "The Python scripts are authoritative" (`cli-dimensions-and-formulas.md:9`) yet restates all constants — a drift hazard. The weights table (`cli-dimensions-and-formulas.md:23-33`) duplicates `WEIGHTS` in `lib/aggregation.py:10-19`.
**Fix:** keep `lib/` authoritative for numeric constants and have the doc reference function names rather than re-printing every coefficient, or generate the doc's tables from the code.

### 4. (Medium) Description has no near-miss exclusion clause
`agents/cognitive-load-analyzer.md:3` leads with the use case (good) but never says what it is *not* for. Sibling skills overlap on "complexity/maintainability/refactoring" intents (refactoring-guide, object-calisthenics-review, code-review, branch-review). Without an exclusion clause and with the trigger harness blocked, mis-fire risk is unquantified.
**Fix:** append a "Not for…" sentence steering refactoring, OO-design scoring, and branch QA elsewhere; then run `test_triggers` once a SKILL.md exists.

### 5. (Low) Hygiene: `__pycache__` not git-ignored; misplaced shebang
- `lib/__pycache__/` exists on disk and is **untracked but not ignored** — the session-start `git status` shows `?? .../cognitive-load-analyzer/lib/__pycache__/`. One careless `git add -A` commits compiled bytecode (and a 3.14-specific `.pyc` ABI). Add `__pycache__/` and `*.pyc` to `.gitignore`.
- `lib/cli_calculator.py:1-2` puts the attribution comment on line 1 and `#!/usr/bin/env python3` on line 2, so the shebang is inert (shebangs must be line 1). The script is invoked as `python …` anyway, so either fix the order or drop the shebang. Same comment-on-line-1 pattern is in every `lib/*.py` (harmless elsewhere).

### 6. (Informational, not a defect) Supply chain is clean
Confirmed by scan across `lib/*.py`: the only import touching the platform is `import sys` (`cli_calculator.py:15`, for argv/exit/stdout). No `requests`/`urllib`/`socket`/`http`/`subprocess`/`os.system`/`pickle`/`eval`/`exec`/`__import__`/`base64`. No third-party dependencies (no `requirements.txt`/`pyproject.toml` needed — pure stdlib `math`, `hashlib`, `json`, `warnings`, `pathlib`, `collections`). No long base64/hex blobs. The calculator is deterministic and ran correctly in a smoke test (`aggregate` of all-0.5 → `cli_score 500`). Roles are clearly stated: `cli_calculator.py` is the executed entry point (`agents/...md:28`), the others are imported library modules. `warnings.filterwarnings("ignore")` (`cli_calculator.py:20`) is a defensible stdout-hygiene choice given JSON-on-stdout, though it could mask genuine deprecations. The external attribution to Andrea Laforgia's public repo is disclosed in every file header.

## Recommendations (prioritized)

1. **Resolve the identity (blocker).** Decide agent vs skill. If skill: add `skills/cognitive-load-analyzer/SKILL.md`, move the agent body into it, and re-run `validate_skill` then `test_triggers` to establish the floor. If agent: stop labeling the directory a skill and document it as an agent with bundled references — but then the skill-eval tooling will never apply, which is the trade-off.
2. **Add TOCs** to both reference files (they are >100 lines).
3. **De-duplicate constants** so `lib/` is the single source of truth for midpoints/steepness/weights; have the docs reference function names.
4. **Add a near-miss exclusion clause** to the description, then run the trigger probe.
5. **Git-ignore `__pycache__/` and `*.pyc`**; fix or remove the line-2 shebang in `cli_calculator.py`.
