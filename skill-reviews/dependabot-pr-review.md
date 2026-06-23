# Skill Review: dependabot-pr-review

**Summary:** A well-scoped, genuinely useful procedural skill for re-authoring and verifying Dependabot PRs; the validator floor passes clean and triggers are well-drawn, but the skill is long and reference-heavy (358 lines, all inline) with no extraction into linked references, and it carries one banned construct (a "Common Pitfalls" anti-pattern table that edges toward a rationalization table). **Overall verdict: PASS WITH WARNINGS** — ship-able, but should split content into references and trim the pitfalls/triage duplication.

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` ran against the directory and returned a clean pass:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":358,"description_chars":189,"reference_files":0}}
```

- **Errors:** none → deterministic floor PASS.
- **Warnings:** none.
- **Stats of note:** `skill_md_lines: 358` (under the 500-line hard limit, but well above the 100-line threshold at which a TOC + reference extraction is expected); `reference_files: 0` (everything is inline in one file); `description_chars: 189` (well within 1024).

Manual cross-checks against house rules:
- Name `dependabot-pr-review` is ≤64 chars, lowercase + hyphens, matches the directory name, contains no `claude`/`anthropic`. PASS.
- Description is third person, single block, no XML/HTML tags. PASS.
- SKILL.md is 358 lines (<500). PASS on the hard limit; see Structure finding on the soft expectation.
- Eval count: there are **no eval files** bundled (`reference_files: 0`, directory contains only `SKILL.md`). The skill-craft rule expects ≥3 evals. **This is a gap** (see Findings F3). The validator does not gate on it, so the floor remains PASS, but the skill ships unbenchmarked.

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` was run twice (10 queries × 3 runs, then 6 queries × 1 run). **Both runs were unusable**: every probe session returned an `infra_error` rather than a genuine trigger/no-trigger result. First run: 29 of 30 runs were infra errors, budget exhausted at \$2.91; the single non-infra result (`pass:true` on the CVE near-miss) is the only datapoint that landed. Second run: 6 of 6 infra errors. The harness could not spawn headless probe sessions during this review, so the trigger eval is **inconclusive by tooling, not by skill quality**.

Falling back to a manual analysis of the description as the listing surface:

> `Use when reviewing, resolving, merging, or managing a Dependabot PR, including grouped and security bumps. Not for general PR review, hand-written dependency changes, or non-dependency PRs.`

Should-trigger queries (manual judgment — strong match, "Dependabot PR" is a concrete, unambiguous noun phrase):
- "Review this Dependabot PR before I merge it" — direct.
- "Grouped dependabot bump open, help me resolve and merge" — explicitly covered ("grouped … bumps").
- "Dependabot security bump for a GHSA advisory" — explicitly covered ("security bumps").
- "A few open dependabot PRs, how should I handle them?" — "managing a Dependabot PR" covers it.

Near-miss / should-NOT-trigger (the description's second sentence draws these exclusions explicitly and well):
- "Review this PR for me before merge" (general PR) — excluded by "Not for general PR review."
- "I manually bumped lodash in package.json" — excluded by "hand-written dependency changes."
- "Review my feature branch that adds an endpoint" — excluded by "non-dependency PRs."
- "Remediating CVE-2024-1234, pin the dependency" — correctly belongs to `cve-remediation`; this skill's description doesn't claim advisory remediation, and the sibling `cve-remediation` description explicitly hands off ("not for routine dependency upgrades or Dependabot bumps (see dependabot-pr-review)"). The one real probe datapoint confirmed this near-miss did **not** trigger (`pass:true`).

Manual verdict: the trigger surface is **well-constructed** — key use case first, concrete noun ("Dependabot PR"), three explicit near-miss exclusions, no embedded workflow steps. Recommend re-running `test_triggers` once infra is healthy to get an empirical pass rate; treat the current empirical result as N/A.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | PASS | Clean: 0 errors, 0 warnings. | None. |
| Triggers | PASS | Key use case first, concrete noun, three explicit near-miss exclusions, no workflow steps. Empirical probe inconclusive (infra). | Re-run `test_triggers` when harness is healthy. |
| Structure | WARN | 358 lines all inline; `reference_files:0`; no TOC despite >100 lines; "Quick Reference Commands" duplicates command blocks already shown inline in Steps 2–11. | Extract command-heavy material and the dependabot-command table into linked references; add a short TOC/decision map at top. |
| Over-prescription | PASS | Low MUST/ALWAYS density; explicitly frames judgment calls ("Default is keep-open; close early is a judgement call, not a rule", line 110). Defers to project conventions rather than hard-coding. | None blocking. |
| Conciseness | WARN | Strong "Why" rationale blocks justify the unusual workflow, but the Pitfalls table (281–295), the "Local-vs-CI Discrepancy Triage" list (297–305) and the "Common Pitfalls" rows on the same topic overlap heavily. | Merge the CI-discrepancy pitfall rows into the triage section; cut duplication. |
| Workflow completeness | PASS | 11 numbered phases with explicit gates, failure paths (rebase → same-PR-vs-replacement at 60–73), a dedicated triage section, and clear exit (Step 11). | None. |
| Banned constructs | WARN | "Common Pitfalls" table (281–295) is an anti-pattern/"don't do this" table that approaches a rationalization table; rows like line 291 ("Closing … before merging … You lose the ability to…") restate rules already in the steps. No "Red Flags-STOP" or self-compliance checklist found. | Convert pitfalls to inline point-of-decision warnings within the relevant steps, or keep a short list but drop rows that duplicate step text. |
| Supply chain | PASS | No bundled scripts; all commands are inline `gh`/`git`/`gradle`/`docker` invocations the user runs interactively. `gh api` calls are read-only (alerts). No obfuscation, no piped curl-to-shell. Role (re-authoring rationale) clearly stated at line 10. | None. |
| Hygiene | WARN | MCP-free (good). But: time-sensitive phrasing ("usually 1–5 minutes", line 60); ticket placeholder drifts (`SDB-XXX` in code vs `SD-123-kebab-description`/`dependabot/<ticket>` examples in prose). References the `qa-pr-comment` skill by name (good cross-link). No README/CHANGELOG present. | Soften the timing claim to "wait for the rebase push"; standardize on one ticket placeholder. |

## Findings

Ranked by severity.

### F1 (Medium) — 358 inline lines with zero reference extraction and no TOC
**Evidence:** validator `skill_md_lines: 358`, `reference_files: 0`. The file inlines a full workflow (Steps 1–11), a "Dependabot Commands Reference" table (241–262), "Additional Checks Worth Considering" (270–279), "Common Pitfalls" (281–295), "Local-vs-CI Discrepancy Triage" (297–305), and a "Quick Reference Commands" dump (307–358).
**Why it matters:** The skill-craft house rule expects a TOC and one-level-deep reference extraction once a SKILL.md exceeds ~100 lines, so the agent loads the decision skeleton first and pulls detail on demand. At 358 lines the whole thing is paid into context on every trigger. The command-reference table and the quick-reference command dump are pure lookup material that belong in `reference/dependabot-commands.md` and `reference/commands.md`.
**Fix:** Keep Steps 1–11 (the decision spine) plus the Step-1 classification table inline. Move the Dependabot Commands Reference table, Additional Checks, and Quick Reference Commands into linked reference files; promote the existing "Workflow" block (lines 14–28) into a top-of-file map and link the references from each step.

### F2 (Medium) — Duplication between "Quick Reference Commands", the inline step commands, and the pitfalls/triage sections
**Evidence:** The re-author command block at lines 85–108 is repeated almost verbatim at 322–327; the worktree commands (120–124) repeat at 330–331; the sync block (201–211) repeats at 343–346; the close block (229–232) repeats at 348–350. Separately, the CI-discrepancy guidance appears three times: pitfall row 295 ("Diagnosing a 'regression' before confirming CI's verdict"), pitfall row 294 ("Stale branch vs pre-migrated test image"), and the full "Local-vs-CI Discrepancy Triage" section (297–305).
**Why it matters:** Violates "each fact in one place." Duplicated command blocks drift out of sync on edit, and the triplicated CI-triage content inflates token cost without adding information.
**Fix:** Pick one home for each command (inline step *or* a reference appendix, not both). Collapse the two CI-related pitfall rows into a one-line pointer to the triage section.

### F3 (Medium) — No evals bundled
**Evidence:** Directory contains only `SKILL.md`; `reference_files: 0`; no `evals/` or `eval*.json`.
**Why it matters:** skill-craft expects ≥3 evals so the skill's behavior (does it actually re-author, classify by scope, gate verification) is benchmarked, not just asserted. A procedural skill this opinionated (re-author by default, keep dependabot PR open, drive via slash commands) especially benefits from a baseline-vs-skill comparison.
**Fix:** Add at least 3 evals — e.g. a patch bump (expect Build + unit only), a major/security bump (expect full verification + advisory check), and a stale grouped PR (expect freshness rebase + re-read scope). Run `run_eval` with/without skill.

### F4 (Low) — "Common Pitfalls" table is a borderline rationalization/anti-pattern table
**Evidence:** Lines 281–295, a two-column "Pitfall | Fix" table whose rows largely restate rules already stated in the steps (e.g. 291 "Closing the dependabot PR before merging…", 293 "Re-authoring a stale PR without rebasing first"). Skill-craft flags "anti-rationalization tables" and "Red Flags-STOP" constructs; this is the milder anti-pattern-table form.
**Why it matters:** Anti-pattern tables tend to duplicate the positive instruction and add a "don't rationalize your way out" tone the methodology discourages. It is not a hard FAIL (no self-assessed compliance checklist, no "STOP"), but it is the construct most worth pruning.
**Fix:** Fold the genuinely additive pitfalls (e.g. the pre-migrated-test-image gotcha at 294, which is real domain knowledge) into the relevant step as an inline note; drop rows that merely echo step text.

### F5 (Low) — Time-sensitive phrasing and placeholder inconsistency
**Evidence:** Line 60 "Wait for dependabot to push the rebase (usually 1–5 minutes)"; ticket placeholder is `SDB-XXX` at lines 89, 287, 314 but the prose at line 83 gives examples `SD-123-kebab-description` and `dependabot/<ticket>`. Minor terminology drift.
**Why it matters:** Hygiene rule discourages time-bound claims (timing varies by provider/load) and wants consistent terms/placeholders so the agent copies the right shape.
**Fix:** Replace the timing parenthetical with "wait for dependabot to force-push the rebased branch"; standardize on one placeholder token throughout.

### Non-findings (verified clean)
- **Supply chain:** no bundled executables, no network-fetching scripts, no obfuscation; `gh api` use is read-only alert listing (274). Re-authoring rationale (the skill's most surprising behavior) is stated up front (line 10).
- **Over-prescription:** the skill explicitly marks judgment calls as judgment, not rules (line 110), and repeatedly defers to project conventions (lines 42, 83, 140, 161, 179) rather than hard-coding Gradle. No prefill, no "show your thinking" theater, no anti-laziness scolding.
- **Triggers:** description excludes all three obvious near-misses (general PR, hand-written deps, non-dependency PRs) and coordinates cleanly with the sibling `cve-remediation` skill.

## Recommendations

Prioritized:

1. **Extract references (F1) + de-duplicate commands (F2).** Highest leverage: cuts the file roughly in half, removes drift risk, and aligns with the >100-line reference rule. Move the Dependabot Commands table, Additional Checks, and Quick Reference Commands to `reference/*.md`; keep Steps 1–11 + the classification table inline.
2. **Add ≥3 evals (F3).** Patch / major-security / stale-grouped scenarios; benchmark with `run_eval` baseline vs skill.
3. **Prune the Common Pitfalls table (F4).** Keep only additive domain knowledge (pre-migrated test image); fold the rest into step-level inline notes.
4. **Hygiene pass (F5).** Drop the "1–5 minutes" timing claim; unify the ticket placeholder token.
5. **Re-run `test_triggers`** once the eval harness infrastructure is healthy — the current empirical probe is N/A due to infra errors, and the description deserves a real pass-rate number on record.
