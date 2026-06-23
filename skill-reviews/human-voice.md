# Skill Review: human-voice

**Verdict: PASS with two must-fix issues.** The skill is unusually well-authored — disciplined ordering of edit moves, a strong anti-hallucination protocol, register-aware guidance, and clean prose with no shouting imperatives or banned rationalization constructs. Two problems block a clean pass: a trigger probe shows the description fails to fire on clearly in-scope queries (5/5 non-triggers, zero infra noise), and the skill ships **zero evals**, which the methodology requires (≥3).

## Validator output

`validate_skill` returned `valid: true`, **0 errors**, 5 warnings, 1 info. SKILL.md is 499 lines (just under the 500 limit); description is 345 chars; 1 reference file.

Warnings:
- `unknown-frontmatter-key`: `user-invokable` is not in the agentskills.io spec (SKILL.md frontmatter, line 4). Non-gating; Claude-Code-recognized.
- `bare-relative-path` x3: `references/ai-tells.md` linked as a bare relative path at SKILL.md lines 37, 173, 212. Should be `${CLAUDE_SKILL_DIR}/references/ai-tells.md` so links resolve from any cwd.
- `reference-toc`: `references/ai-tells.md` is 594 lines with no Contents/ToC heading. (It does have a "Quick index of tells" at line 15, but no explicit ToC heading the validator recognizes.)

Info:
- `cc-extension-key`: `argument-hint` (line 5) is Claude-Code-only, not portable. Acceptable for a CC-targeted skill.

No ERROR -> validator floor does not fail.

## Trigger probe

`test_triggers` ran but was heavily degraded by infrastructure errors (first run: 31 of 33 sub-runs failed with infra errors, budget exhausted at $3.11). I re-ran narrower probes to isolate real signal from noise.

The decisive run — query **"Make this draft sound less like it was written by AI"** (`should_trigger: true`), **5 runs, 0 infra errors** — returned `trigger_rate: 0, pass: false`. The skill did **not** invoke on a plainly in-scope request. Two other positive queries ("reads like ChatGPT ... make it sound human", "Rewrite my blog draft so it doesn't sound AI-generated") also returned `trigger_rate: 0` on their non-infra runs.

Near-miss negatives behaved correctly: "Review this Python module for bugs" -> `pass: true` (stayed quiet); the code-generation and translation negatives also did not fire. So the description is not over-broad — it is **under-triggering** on its own primary use case.

Caveat: infra noise was high overall, but the 5-run/0-infra result is clean and is the strongest single data point. This is a real description-recall problem, not a harness artifact.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | PASS | 0 errors; 5 warnings (bare paths, missing ToC heading, unknown key) | Qualify the 3 reference links with `${CLAUDE_SKILL_DIR}`; add a ToC heading to ai-tells.md |
| Triggers | FAIL | Clean 5/0 probe shows non-trigger on "make this sound less like AI"; 3 positives at trigger_rate 0 | Front-load the verb the user actually types ("make X sound human / not AI-written"); see Findings |
| Structure | PASS | Point-of-decision guidance is inline; reference is one level deep; each fact mostly lives in one place | Minor: top-tell list duplicates ai-tells.md quick index (see Findings) |
| Over-prescription | PASS | Zero uppercase MUST/ALWAYS/CRITICAL; "never" used 25x but as ordinary prose for genuine prohibitions (don't fabricate, don't alter numbers) | None |
| Conciseness | WARN | At 499/500 lines, dense; some passages restate the reference and re-explain detector theory Claude largely knows | Trim duplicated tell lists and the detector-theory exposition; push depth into the reference |
| Workflow completeness | PASS | Clear gates, a capped self-critique loop (<=3 passes), explicit exit conditions, failure path when the linter is unavailable | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance/attestation, no "Red Flags — STOP" theatre | None |
| Supply chain | PASS | Scripts are pure stdlib; no network/subprocess/eval/exec; only file write is the documented `--fix` in-place edit | None |
| Hygiene | WARN | Committed `__pycache__/` (untracked .pyc churn); no `when_to_use` field; dated refs ("newer detectors", "Liang et al. (2023)") | gitignore `__pycache__`; consider a `when_to_use`; date-stamp or soften "newer" |

## Findings (ranked by severity)

### 1. (HIGH) Skill does not trigger on its own primary use case
Clean probe (5 runs, 0 infra errors) on "Make this draft sound less like it was written by AI" -> `trigger_rate: 0, pass: false`. Two further positives also at trigger_rate 0. The description leads with **"Use when generating or rewriting reports, documentation, or any prose so it does not read as AI-written"** (SKILL.md line 3). The phrasing is accurate but abstract — it never contains the high-frequency user phrasings ("sound human", "doesn't sound like AI / ChatGPT", "de-AI-ify", "sound less robotic"). The skill name `human-voice` carries the intent but the description's opening clause is the weakest part of the listing surface.

**Fix:** rewrite the first clause around the verb+object users actually type. Example: *"Use when the user wants prose to sound human and not AI-written — rewriting an AI-sounding draft, or generating new copy that reads human from the start (reports, docs, marketing, blog, email, academic)."* Then re-run `test_triggers` (raise budget / lower concurrency to dodge infra exhaustion) and confirm recall recovers.

### 2. (HIGH) No evals shipped
The REVIEW deterministic floor expects >=3 evals. The directory contains no eval files — `scripts/ai_prose_patterns.json` is linter config, not a skill eval, and `find` for `*eval*` returns nothing. There is no `evals/` directory or `run_eval` workspace.

**Fix:** author at least 3 baseline-first evals (with_skill vs without_skill) asserting the observable behaviors the skill promises — e.g. invariant preservation (numbers/code/links unchanged), em-dash density dropping outside `creative`, and a refusal-to-fabricate case (the skill already ships `examples/refusal-to-fabricate.md` and `examples/restraint-case.md` as ready-made fixtures). Use the skill-eval MCP `run_eval`.

### 3. (LOW) Reference links are bare relative paths
SKILL.md lines 37, 173, 212 link `references/ai-tells.md` relatively; line 414 links `STYLE-GUIDE.md`. These break when cwd is not the skill dir.
**Fix:** prefix with `${CLAUDE_SKILL_DIR}/`.

### 4. (LOW) Reference file lacks a ToC heading
`references/ai-tells.md` is 594 lines. It has a usable "Quick index of tells" (line 15) but no heading the validator accepts as a Contents/ToC.
**Fix:** rename or add a `## Contents` heading near the top.

### 5. (LOW) Committed `__pycache__/`
`git status` shows `claude/.claude/skills/human-voice/scripts/human_voice_linter/__pycache__/` as untracked. Bundling compiled `.pyc` adds churn and platform-specific artifacts (here `cpython-314`).
**Fix:** add `__pycache__/` / `*.pyc` to `.gitignore` and remove the directory from the package.

### 6. (LOW / token cost) Some content is duplicated and over-explained
The "Top tells (curated)" list (SKILL.md 169-208) substantially restates the quick index in `references/ai-tells.md` (15-49); the "What detectors actually measure" section (28-47) re-explains perplexity/burstiness/stylometry the model already knows. At 499/500 lines the file is one edit from exceeding the limit.
**Fix:** keep a short pointer to the reference for the full list, trim the detector-theory exposition to the load-bearing parts (the honest-measurement caveat and the burstiness lever), reclaiming headroom under the 500-line cap.

### 7. (INFO) Time-sensitive phrasing
"the newer detectors (Binoculars, DetectGPT, Ghostbuster)" (line 36) and "The newer structural checks" (line 417) will age. The Liang et al. (2023) citation (line 44) is a real source, so keep it; just avoid "newer" as a standalone temporal claim.
**Fix:** drop "newer" or anchor it ("as of 2024").

## Recommendations (prioritized)

1. **Fix the description recall (Finding 1)** — re-anchor the opening clause on user phrasings ("sound human", "not AI-written / not ChatGPT", "de-AI-ify"), then re-run `test_triggers` with a raised budget to confirm.
2. **Add >=3 evals (Finding 2)** — reuse the existing `examples/` fixtures (refusal-to-fabricate, restraint-case) as ground truth; assert invariant preservation and em-dash reduction.
3. **Qualify reference links and add a ToC heading (Findings 3-4)** — clears 4 of 5 validator warnings.
4. **gitignore `__pycache__` (Finding 5)** and date-soften "newer" (Finding 7).
5. **Trim duplication to bank line-limit headroom (Finding 6)** — defensive, since the file sits at 499/500.
