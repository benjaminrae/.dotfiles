# Skill Review: branch-review

A well-structured multi-agent orchestration skill that passes the validator cleanly, but ships internal contradictions (agents told both to never run `git diff` and to run it), a hardcoded `main` base that defies its own "ask for BASE_BRANCH" rule, unverified orchestration tool names, and zero bundled evals. **Overall verdict: WARN.**

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` on the skill directory returned:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":141,"description_chars":399,"reference_files":0}}
```

- Errors: none.
- Warnings: none.
- Deterministic floor: PASS. Name `branch-review` is lowercase-hyphen, matches the dir, no banned tokens. Description is 399 chars (within 1–1024), third person, no XML. SKILL.md body is 141 lines (< 500). `reference_files: 0` — the skill bundles no progressive-disclosure `references/`; its extra files are `agents/*.md` (sub-agent prompt files) and `report-template.md`, all loaded by spawned agents, so the one-level reference rule does not bite.

The one floor item the validator does **not** check: the methodology expects **≥3 evals**. This skill ships **zero** eval files. Counts as a floor gap (see Findings).

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` was run with 11 curated queries (6 should-trigger, 5 near-miss) at 3 runs each. **The harness failed: 33/33 runs returned `infra_errors` (every isolated probe session failed to start). `passed: 0, failed: 0, infra_errors: 33, total_cost_usd: 3.3`.** No trigger signal was produced — these are infrastructure failures, explicitly not "did not trigger." The probe is inconclusive.

Manual fallback reasoning (description quality, not measured activation):
- **Listing not truncated** — 399 chars, well under the 1536-char cutoff. Good.
- **Positive coverage**: the description leads with the use case ("reviewing a feature branch or PR before merging") and embeds concrete trigger quotes (`"review this branch"`, `"code review"`, `"review report"`, `"QA before merge"`). Plausible strong activation for branch/PR review requests.
- **Near-miss risk**: `"code review"` is a very broad quoted trigger. It overlaps heavily with the `code-review` skill ("single-diff inline review") and `qa-pr-comment`. The exclusion clause helps ("Not for ... a single-diff inline review (use code-review)"), but a bare "do a code review" is genuinely ambiguous between this skill and `code-review` and may misfire in either direction. This is the main trigger risk and cannot be confirmed without a working probe.

Re-run `test_triggers` once the harness is healthy before trusting activation.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | WARN | Validator passes (0/0/0), but methodology requires ≥3 evals and the skill bundles none. | Add at least 3 evals (e.g. clean branch → PASS; branch with an arch violation → FAIL + action item; agent-timeout path → "AGENT FAILED" section). |
| Triggers | PASS | Third person, use-case-first, concrete quoted nouns, near-miss exclusion clause present. Bare `"code review"` overlaps with `code-review` skill. | Consider narrowing `"code review"` to `"branch code review"` / `"full branch review"` to reduce collision; re-probe. |
| Structure | WARN | Point-of-decision content mostly inline (gates, routing tables, common-mistakes). Base/optional agent file contents live only in `agents/*.md`, loaded by spawned agents — acceptable for orchestration. Report-destination logic (Step 1.6) is heavy and correctly inline. | No structural move needed; see contradiction findings below. |
| Over-prescription | PASS | MUST/ALWAYS/NEVER/CRITICAL density is low: 5 hits in 141 SKILL.md lines; agent files 0–5 each. No anti-laziness pushes, no "if in doubt", no "show your thinking". Appropriately terse. | None. |
| Conciseness | PASS | Tables and terse imperatives; little educational prose. Step 1.6 is long but it is decision logic, not explanation. | Optional: trim Step 1.6 prose slightly. |
| Workflow completeness | PASS | Explicit phases with gates: pre-compute diff before agents; "Abort if `git diff` fails"; failure path for agent timeout ("AGENT FAILED -- rerun review"); explicit exit (Step 6 summary). | None. |
| Banned constructs | PASS | No Rationalization/Reality table, no self-assessed compliance checklist, no self-directed "Red Flags — STOP" section. "Common Mistakes" table is a routing aid, not anti-rationalization. | None. |
| Supply chain | PASS | No bundled executable scripts; all inline bash is local git/`grep`/`ls`/`sed`/`mkdir`, no network calls, no obfuscation. `cat ~/.claude/skills/postgresql-guidelines/...` reads a local sibling skill with a documented fallback. Each agent's role is stated. | None. |
| Hygiene | FAIL | (1) Self-contradiction: agents told to never run `git diff` yet two agent files run it. (2) Hardcoded `main` contradicts the "ask for BASE_BRANCH" rule. (3) Orchestration tool names (`TaskOutput`, `run_in_background`) are not fully-qualified / may not match this harness's tool surface. | Fix the contradictions; verify and standardize the orchestration tool names. |

## Findings

Ranked by severity. Evidence quoted with file + line.

### 1. (HIGH) Two agent files run `git diff` directly, contradicting the skill's central invariant

SKILL.md establishes a hard rule and even lists violating it as a top "Common Mistake":

- `SKILL.md:22` — "Agents must not run `git diff` themselves."
- `SKILL.md:137` — "| Agents run `git diff` themselves | Pre-compute diff in Step 1.5; agents read the file |"
- `SKILL.md:139` — "| No diff file = hallucination | Abort if `git diff` fails — never launch agents without valid diff |"

The architecture, standards, and test-quality agents honour it (each opens with "**NEVER run `git diff` yourself**"). But two do not:

- `agents/postgresql-review.md:13-14`:
  ```
  git diff main...{branch} -- '*.sql'
  git diff main...{branch} -- '**/migrations/**'
  ```
- `agents/automated-checks.md:38` — "Per-file coverage for changed files (`git diff --name-only main...{branch}`)"

**Why it matters:** the whole anti-hallucination design (pre-compute once, agents read files) is undermined for SQL and coverage; these agents can compute a different diff than the orchestrator handed the others, and they bypass the "abort if git diff fails" guard.

**Fix:** have these agents read `{tmp}/diff.txt` / `{tmp}/changed-files.txt` like the others. If SQL-only or name-only filtering is needed, pre-compute those filtered files in Step 1.5 (e.g. a `sql-diff.txt`) and point the agents at them.

### 2. (HIGH) Hardcoded `main` contradicts the "ask for BASE_BRANCH" rule and the configurable base everywhere else

SKILL.md treats the base branch as a required, possibly-non-`main` input:

- `SKILL.md:25-26` use `${BASE_BRANCH}...${BRANCH}`.
- `SKILL.md:29` — "If BASE_BRANCH is not provided then ask for it."

But the two offending agent files (and the optional-agent prompt) hardcode `main`:

- `agents/postgresql-review.md:13-14` — `git diff main...{branch} ...`
- `agents/automated-checks.md:38` — `git diff --name-only main...{branch}`
- `SKILL.md:99` (optional agent prompt) — "Review `{BRANCH}` vs `main`."

**Why it matters:** on any repo whose default branch is `master`/`develop`/`trunk`, or any review against a non-default base, these paths silently diff against the wrong (or non-existent) base, producing empty or wrong findings while the base agents diff correctly.

**Fix:** thread `{BASE_BRANCH}` into every agent prompt and replace all hardcoded `main`. Combined with Finding 1, the cleanest fix is to remove agent-side `git diff` entirely and pass pre-computed, base-correct files.

### 3. (MEDIUM) Orchestration tool names are unverified / not fully qualified

SKILL.md drives the pipeline with `run_in_background: true` and a `TaskOutput` tool:

- `SKILL.md:101` — "All `run_in_background: true`."
- `SKILL.md:103` — "After each agent completes via `TaskOutput`, write the returned text ..."
- `SKILL.md:107` — "`TaskOutput` `block: true`, `timeout: 300000` per agent."

The hygiene rule asks for fully-qualified, real tool names. In the current Agent/Task surface there is no `TaskOutput` tool — an agent dispatched via the Agent tool returns its result directly as the tool result; background polling uses a different mechanism (e.g. a monitor/output tool). At minimum these names are unqualified and may be stale for the target harness.

**Why it matters:** if the names don't match the runtime, the orchestrator improvises the wait/collect step, which is exactly where parallel-agent skills break (foreground execution, lost output, double-writing files).

**Fix:** confirm the exact tool names in the deployment harness and use them verbatim; if the harness returns agent results synchronously, drop the `TaskOutput` indirection and describe the actual collect step. Add a one-line note in `SKILL.md:103-107` naming the real tool.

### 4. (LOW) Zero evals bundled

The methodology floor wants ≥3 evals; none exist in the directory (`find` shows only SKILL.md, `agents/`, `report-template.md`). The skill has rich, testable behavior (verdict computation, agent-failure handling, report-path detection, finding filtering) that would benefit from `run_eval` coverage.

**Fix:** add ≥3 evals covering: a clean branch → PASS report; a branch with a planted architecture/standards violation → FAIL with that action item present; an injected agent timeout → section marked "AGENT FAILED -- rerun review" and overall FAIL.

### 5. (LOW) `"code review"` trigger collides with the `code-review` skill

`SKILL.md:3` lists `"code review"` as a bare quoted trigger. The same description's exclusion clause routes single-diff inline review to `code-review`. A user typing "do a code review" is ambiguous between the two. The exclusion clause mitigates but does not eliminate the overlap.

**Fix:** qualify the quoted trigger to `"branch code review"` / `"full branch review"` and re-run `test_triggers` once the probe harness works.

### 6. (INFO) Minor doc nits

- `report-template.md:4` describes itself as read by the compiler and references `reviews/.tmp/<branch>/` — consistent with SKILL, fine.
- The `automated-checks` agent (`automated-checks.md:5`) carefully distinguishes log redirection from the findings file — good, no change needed.
- Step 1.6 (`SKILL.md:33-57`) is long but it is genuine decision logic (report-destination convention detection), correctly inline at the point of decision. Acceptable; could be tightened but not a defect.

## Recommendations

Prioritized:

1. **Fix the `git diff` contradiction (Finding 1)** — make `postgresql-review.md` and `automated-checks.md` consume the pre-computed `{tmp}` files instead of running `git diff`. This is the most damaging defect because it silently breaks the skill's core anti-hallucination guarantee.
2. **Remove all hardcoded `main` (Finding 2)** — thread `{BASE_BRANCH}` into every agent prompt, including the optional-agent prompt at `SKILL.md:99`. Best done together with (1).
3. **Verify and qualify the orchestration tool names (Finding 3)** — confirm `TaskOutput` / background-run semantics against the real harness and write the exact tool names.
4. **Add ≥3 evals (Finding 4)** — cover PASS, FAIL-with-action-item, and agent-failure paths.
5. **Narrow the `"code review"` trigger and re-probe (Finding 5)** once `test_triggers` infrastructure is healthy — the current run was 33/33 infra failures and gave no activation signal.
