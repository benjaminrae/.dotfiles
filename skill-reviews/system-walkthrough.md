# Skill Review: system-walkthrough

**Summary:** `system-walkthrough` is registered as an *agent* (`agents/system-walkthrough.md`), and `skills/system-walkthrough/` holds five reference files with **no `SKILL.md` entry point** — so as a *skill* it is non-loadable and fails the deterministic validator floor. **Overall verdict: FAIL** (hard block: missing `SKILL.md`). The underlying content is strong; the packaging is wrong.

---

## Validator output

`validate_skill` was run against `/Users/benjamin.rae/cowork/dev/.dotfiles/claude/.claude/skills/system-walkthrough`:

```json
{"valid":false,
 "errors":[{"rule":"skill-md-missing","message":"no SKILL.md in the skill directory","file":"SKILL.md"}],
 "warnings":[],"info":[],
 "stats":{"skill_md_lines":0,"description_chars":0,"reference_files":0}}
```

**ERROR — `skill-md-missing` at `SKILL.md` → FAIL.** Directory listing confirms it (`ls` of the dir):

```
analysis-pipeline.md   code-validation.md   comprehension-models.md
narrative-structure.md slide-architecture.md
```

There is no `SKILL.md` (any casing) and none is git-tracked. The skills spec requires `SKILL.md` as the entry point carrying `name` + `description` frontmatter; without it the skill has no listing surface, no triggers, and cannot be invoked through the Skill tool.

### What is actually wired up
The name `system-walkthrough` is registered as an **agent**: `agents/system-walkthrough.md:2-13` declares `name: system-walkthrough` and lists the five files under a `skills:` frontmatter key:

```
8	skills:
9	  - analysis-pipeline
10	  - narrative-structure
11	  - slide-architecture
12	  - code-validation
13	  - comprehension-models
```

Each referenced "skill" is itself a single flat `.md` file with only `name` + `description` frontmatter (e.g. `analysis-pipeline.md:1-4`) and **no `SKILL.md`** — so each named sub-skill would also fail `validate_skill` for the same reason. The review target is therefore better understood as one agent + five bundled reference docs, none of which is a spec-conformant skill.

### Manual floor checks (on the five reference files, for completeness)
- **name**: all five frontmatter `name`s are lowercase-hyphen and match their filenames. PASS in isolation.
- **description**: third person, single sentence, well under 1024 chars. PASS in isolation.
- **SKILL.md < 500 lines**: N/A — no SKILL.md. Reference files are 152–210 lines each (all < 500).
- **refs one level deep + TOC if >100 lines**: the reference files contain **no table of contents** despite all exceeding 100 lines (e.g. `slide-architecture.md` = 210 lines). WARN.
- **≥3 evals**: **none present** anywhere in the directory or the agent. FAIL.

---

## Trigger probe

`test_triggers` could not run — it aborted with:

```
test_triggers failed: ENOENT: no such file or directory,
open '.../skills/system-walkthrough/SKILL.md'
```

The probe is **blocked by the same missing `SKILL.md`**. There is no skill-level `description`/`when_to_use` listing surface to test, so trigger quality cannot be measured at the skill layer.

Manual assessment of the *agent* description (`agents/system-walkthrough.md:3`), which is the real selection surface:

> "Use for generating comprehensive system walkthroughs from codebases. Analyzes design, architecture, code, testing, and infrastructure, then produces slide-based narrative presentations (Marp Markdown) explaining what the system does, how it's organized, and why decisions were made. Also validates AI-generated code quality."

- Third person, concrete nouns (Marp Markdown, slide-based presentations), key use case stated first. Good.
- **No near-miss exclusion.** Nothing steers the model away from general "explain this code" / "write a README" requests, which is exactly the near-miss class this review is asked to guard. A user asking "explain how auth works" could plausibly pull this heavyweight 5-phase deck generator. WARN.

---

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | **FAIL** | `skill-md-missing`: no `SKILL.md` in the directory; validator returns `valid:false`. The five sub-"skills" are flat `.md` files, not skill dirs. | Add a `SKILL.md` entry point with `name: system-walkthrough` + a triggering `description`. Either convert this directory into a real skill, or (preferred) keep it as the agent it already is and move the five files to a non-`skills/` reference location. |
| Triggers | **WARN** | No SKILL.md description to test; agent description has no near-miss exclusion (`agents/system-walkthrough.md:3`). | In the new `SKILL.md` description, lead with the use case and add an explicit "Not for general code explanation or README generation — use only when a full slide-deck walkthrough is wanted." |
| Structure | **WARN** | Reference files >100 lines lack a TOC (e.g. `slide-architecture.md` 210 lines, `analysis-pipeline.md` 177). Point-of-decision links are absent — the agent says "Load the X skill" but files don't cross-link. | Add a short TOC to each >100-line reference; have `SKILL.md` link directly to each reference at its point of use. |
| Over-prescription | **PASS** | No `MUST`/`CRITICAL`/`ALWAYS` inflation in the reference files. The only `Red Flag` token is a benign table column header (`code-validation.md:51`). Agent uses measured "Gate:" language. | None. |
| Conciseness | **PASS (minor)** | Largely high-signal. Some research-citation framing is educational rather than instructive (`comprehension-models.md:15-51`, Brooks/Pennington/Soloway) — justified here as it shapes output structure, but adds tokens. | Optional: trim citation prose to the actionable "Agent implication" lines. |
| Workflow completeness | **PASS** | The agent defines 5 phases each with an explicit **Gate** (`agents/system-walkthrough.md:53,67,80,94,107`) and reduced-depth/overview exit paths (Example 4, `*overview`). Clear phase separation analysis→narrate→generate→validate. | None — this is the strongest dimension. Consider stating a failure path when a gate is not met (e.g. "if no git history, skip Layer 2 and flag it"). |
| Banned constructs | **PASS** | No anti-rationalization tables, no self-assessed-compliance scoring of the *skill itself*, no "Red Flags – STOP" blocks. (The Cognitive Load / Validation checklists are about the *output artifact*, not skill compliance, which is legitimate.) | None. |
| Supply chain | **PASS** | No bundled executable scripts; all five files are pure Markdown. No network calls, no obfuscation, no pinned deps to audit. Bash usage is illustrative (`git log` snippet, `analysis-pipeline.md:52-54`), not a packaged script. Attribution header present on every file. | None. |
| Hygiene | **WARN** | (1) Author-supplied description name "Atlas System Walkthrough Agent" leaks into output footer (`slide-architecture.md:21`) — a vanity string in generated decks. (2) Terminology drift: the doc calls these "skills" but they are reference files attached to an agent. (3) No fully-qualified MCP names anywhere (none needed). (4) No README/CHANGELOG (good). | Replace the "Atlas …Agent" footer with a neutral or templated value; align terminology ("references" vs "skills"); after adding `SKILL.md`, re-run the validator. |

---

## Findings (ranked by severity)

### 1. BLOCKER — No `SKILL.md`; the skill cannot load or trigger
Evidence: validator returns `{"valid":false,"errors":[{"rule":"skill-md-missing", ... "file":"SKILL.md"}], ... "reference_files":0}`. `test_triggers` aborts with `ENOENT … SKILL.md`. Directory contains only the five reference `.md` files.

Why it matters: a skill directory with no `SKILL.md` has no name, no description, no `when_to_use` — nothing the harness can surface or invoke. Every downstream dimension that depends on a description (triggers, near-miss exclusion) is untestable.

Fix — pick one:
- **(A) It's really an agent (recommended).** It already works as `agents/system-walkthrough.md`. Move the five files out of `skills/` (e.g. to `agents/system-walkthrough/references/`) so they are not mistaken for skills, and drop the `skills/system-walkthrough/` directory. Then this review's "skill" target ceases to exist by design.
- **(B) Make it a real skill.** Add `skills/system-walkthrough/SKILL.md` with `name: system-walkthrough`, a triggering `description` (with near-miss exclusion), and a body that links to the five references at their point of use. The five files stay as references one level deep.

### 2. HIGH — Zero evals
Evidence: no eval files in the directory or alongside the agent; manual floor check "≥3 evals" → none.

Why it matters: skill-craft requires baseline-first evals (≥3) to prove the skill changes behavior and to pressure-test triggering. Without them there is no regression guard for the 5-phase workflow or the trigger boundary.

Fix: after resolving Finding 1, author ≥3 evals — at least one should-trigger ("generate a Marp walkthrough deck for this repo"), one near-miss negative ("explain what this file does"), and one behavior eval asserting the 7-section / gated-phase output.

### 3. MEDIUM — No near-miss trigger exclusion
Evidence: `agents/system-walkthrough.md:3` description lists positive use cases only; nothing excludes general code explanation or README generation.

Why it matters: the near-miss class (general explanation, README) overlaps the positive surface and risks over-triggering a heavyweight deck generator.

Fix: append an exclusion clause to the description, e.g. "Not for a one-off explanation of a single function, general Q&A about the code, or generating a README."

### 4. MEDIUM — Reference files >100 lines have no TOC and no point-of-decision linking
Evidence: `slide-architecture.md` (210 lines), `analysis-pipeline.md` (177), `narrative-structure.md` (181), `code-validation.md` (158), `comprehension-models.md` (152) — all exceed 100 lines, none has a TOC. The agent says "Load the `comprehension-models` skill for details" (`agents/system-walkthrough.md:32`) but no inline link is provided.

Fix: add a brief TOC to each reference; in `SKILL.md` (or the agent body), link each reference inline where its decision point occurs rather than by name only.

### 5. LOW — Vanity string in generated output footer
Evidence: `slide-architecture.md:21` — `footer: "Generated {date} | Atlas System Walkthrough Agent"`.

Why it matters: hardcodes a persona/brand into every produced deck; minor, but it is author-facing identity bleeding into the artifact.

Fix: make the footer templated or neutral (e.g. `footer: "Generated {date}"`).

### 6. LOW — "skills" vs "references" terminology drift
Evidence: agent frontmatter `skills:` (`agents/system-walkthrough.md:8`) names files that are not spec-conformant skills.

Fix: align naming once Finding 1 is resolved; if kept as agent references, avoid the `skills:` framing or ensure each truly becomes a `SKILL.md`-backed skill.

---

## Recommendations (prioritized)

1. **Resolve the entry-point problem (Finding 1).** Decide skill-vs-agent. Given the gated 5-phase workflow, `maxTurns: 50`, and tool list, this is an **agent** — keep it as `agents/system-walkthrough.md` and relocate the five references out of `skills/`. Re-run `validate_skill` only if you choose to keep a real skill.
2. **Add a near-miss exclusion clause** to the agent/skill description (Finding 3).
3. **Author ≥3 evals** covering trigger, near-miss, and the 7-section gated output (Finding 2).
4. **Add TOCs** to the five >100-line references and link them at their point of use (Finding 4).
5. **Neutralize the deck footer vanity string** (Finding 5).
6. **Re-validate**: after restructuring, run `validate_skill` and `test_triggers` again to confirm the floor is clean and triggers fire on deck requests while staying quiet on "explain this function" / "write a README".

**Strengths worth preserving:** clean phase-gated workflow with explicit exit conditions; no over-prescription or banned constructs; no supply-chain risk (pure Markdown, attributed); research-grounded but action-oriented content. The problem is entirely structural/packaging, not substantive.
