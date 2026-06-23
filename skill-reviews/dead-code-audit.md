# Skill Review: dead-code-audit

A genuinely strong, domain-deep audit skill that the validator passes cleanly and that triggers reliably; the only real defects are bare relative reference paths (validator warnings), missing ToC headings on long reference files, and one near-miss over-trigger on "unused import". **Overall verdict: PASS with minor fixes.**

## Validator output

`validate_skill` returned `valid: true`, `errors: []`. Stats: `skill_md_lines: 147` (well under the 500 cap), `description_chars: 450` (inside 1–1024), `reference_files: 7`.

Warnings (all non-gating, none safe to fully ignore):

- **`bare-relative-path` ×9** at SKILL.md lines 20, 24, 28, 49, 54, 67, 78, 82, 112. Every reference link is written as `[references/foo.md](references/foo.md)` rather than `${CLAUDE_SKILL_DIR}/references/foo.md`. `grep` confirms `CLAUDE_SKILL_DIR` appears nowhere in the skill. These links resolve only when cwd is the skill directory; when the skill runs from a target project root (its entire purpose) the relative links are broken. This is the one warning class that should be fixed, not ignored.
- **`reference-toc` ×6**: `canary-pattern.md` (143 lines), `detectors.md` (155), `entry-points.md` (103), `reflection-checklist.md` (180), `report-template.md` (120), `verify-candidate.md` (187) each exceed ~100 lines with no Contents/ToC heading. The house rule wants a ToC on references over 100 lines so Claude can jump to a section without loading the whole file. Reasonable to fix; low blast radius.

No ERROR-level findings, so there is no validator FAIL gate.

## Trigger probe

First run (10 queries, 3 runs each) was contaminated by infrastructure errors: **22 of 30 runs failed with infra_errors**, including all 3 runs of four of the five positive queries. Those `pass: null` results are inconclusive, not non-triggers. I re-ran the five positives (2 runs, concurrency 2):

| Query | should_trigger | trigger_rate | Verdict |
|-------|---------------|--------------|---------|
| "What code in this Spring Boot service is safe to delete?" | true | 1.0 | PASS |
| "Audit our Gradle Java project for dead or unused code" | true | 1.0 | PASS |
| "Find unused classes and dead REST endpoints before we retire this service" | true | 1.0 | PASS |
| "I want to clean up legacy code in our Java app before the upgrade" | true | 0.5 | PASS (at threshold) |
| "Can you instrument the possibly-dead methods as canaries and give me a removal report?" | true | 1.0 | PASS |

Negatives (infra-error-free runs from the first pass are reliable):

| Query | should_trigger | trigger_rate | Verdict |
|-------|---------------|--------------|---------|
| "Delete the OrderLegacyService class, I know it's unused" | false | 0.0 | PASS (near-miss: single known class) |
| "Find dead code in our React TypeScript frontend" | false | 0.0 | PASS (near-miss: non-JVM) |
| "Remove the unused import in UserController.java" | false | 0.33 (1/3) | **WARN — over-triggered once** |
| "Review this PR for lint findings" | false | 0.0 (3 infra) | inconclusive |
| "Refactor this method to be cleaner" | false | 0.0 (3 infra) | inconclusive |

Net: both required near-misses from the task brief (removing a single known class; non-JVM project) correctly stayed quiet. The "unused import" near-miss fired once out of three — the description's broad nouns "unused classes or methods" / "code cleanup" can over-pull a trivial single-file edit. Below the 0.5 threshold, so not a hard fail, but a real bleed-edge.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | PASS | 0 errors; 15 warnings (9 bare-path, 6 ToC) | Fix bare paths; add ToCs |
| Triggers | PASS | "unused import" near-miss fired 1/3; "single known class" + non-JVM correctly excluded | Tighten nouns or strengthen exclusion clause |
| Structure | PASS | Point-of-decision content inline; references link directly; one minor duplication (degradation guidance) | Optional: dedupe |
| Over-prescription | PASS | MUST/CRITICAL/ALWAYS density low and load-bearing (safety gates); no "show your thinking", no prefill | None |
| Conciseness | PASS | Dense and Spring-specific; little generic explanation of what Claude already knows | None |
| Workflow completeness | PASS | Explicit gates (dirty-tree refusal), failure paths (revert+demote on broken build), exit conditions (graduation) | None |
| Banned constructs | PASS | No anti-rationalization table, no self-assessed compliance checklist, no "Red Flags — STOP" | None |
| Supply chain | PASS | No network calls in either script; no external deps; both scripts read-only with role stated in headers | None |
| Hygiene | WARN | Bare relative links; example dates are illustrative (OK); no README/CHANGELOG; scripts handle errors well | Fix links |

## Findings

### 1. Bare relative reference paths break when run from a project root (MEDIUM)
The skill's whole job is to run *against a target Gradle project*, so cwd at invocation time is the project root, not the skill directory. Every one of the nine reference links is bare-relative, e.g.

- SKILL.md:20 `…full reflection checklist in [references/reflection-checklist.md](references/reflection-checklist.md).`
- SKILL.md:54 `…shipped at [assets/inspection-profile.xml](assets/inspection-profile.xml).`
- SKILL.md:112 `…canary pattern in [references/canary-pattern.md](references/canary-pattern.md):`

`grep -rn CLAUDE_SKILL_DIR` returns nothing. The subagent template (subagent-template.md:15) is actually aware of this problem — it tells the orchestrator to resolve `{SKILL_DIR}` "at orchestration time; do not hardcode it" — but SKILL.md itself never adopts that convention.
**Fix:** rewrite the nine links as `${CLAUDE_SKILL_DIR}/references/<file>` (and `${CLAUDE_SKILL_DIR}/assets/inspection-profile.xml`). Cross-references *inside* reference files (e.g. reflection-checklist.md:43 `[entry-points.md](entry-points.md)`) resolve relative to their own file and are fine.

### 2. Long reference files lack a Contents heading (LOW)
Six references exceed ~100 lines with no ToC: `verify-candidate.md` (187), `reflection-checklist.md` (180), `detectors.md` (155), `canary-pattern.md` (143), `report-template.md` (120), `entry-points.md` (103). Without a ToC, Claude loads the whole file to find a section, costing tokens on every consult. **Fix:** add a short `## Contents` list of the `##` headings at the top of each file over 100 lines.

### 3. Description over-pulls on trivial single-file edits (LOW)
`description` (SKILL.md:3) lists "unused classes or methods" and "code cleanup" as triggers; the probe shows "Remove the unused import in UserController.java" triggering 1/3. The exclusion clause "Not for removing a single known class or non-JVM projects" covers the *known-class* case (which passed 0/3) but not the *single trivial cleanup* case. **Fix (optional):** extend the exclusion to "…or a single-file lint fix such as removing an unused import," or qualify the positive nouns as "project-wide" cleanup. Below threshold, so non-blocking.

### 4. Minor duplication of graceful-degradation guidance (INFO)
SKILL.md:61 states the IntelliJ-absent fallback in prose ("fall back to PMD + the skill's own checklist analysis, and say so in the report header"), and detectors.md:141–151 carries the authoritative degradation table. The two agree, so this is not a contradiction, but it is the same fact in two places — if the table changes, the prose can drift. **Fix (optional):** let SKILL.md point at the table instead of restating the rule.

### Positive observations (no action)
- **Supply chain is clean.** `run-audit.sh` (read-only, `set -euo pipefail`, isolated IDEA config dir, graceful non-zero handling, asks before applying Gradle plugins at lines 112/127) and `parse-intellij.py` (read-only, stated in docstring, no network, defensive JSON parsing) both behave as their headers claim. No obfuscation, no external downloads, no pinned-dep risk.
- **Safety model is excellent and consistent.** The audit/action split (audit read-only on dirty tree; delete & canary phases refuse on dirty tree) is stated identically in the workflow (SKILL.md:48, 97, 111), the Safety Rules table (125–135), and Common Mistakes (147). Failure paths are concrete: "revert that commit and demote the affected candidates to Tier 3" (107).
- **Genuinely deep Spring-awareness** — the reflection checklist (`@Schema enumAsRef`, Spring Data synthesised methods, MapStruct, `META-INF/services`, AOP pointcut-by-pattern) is the kind of domain knowledge that justifies a skill over a one-shot prompt.
- **No banned constructs.** The tables present are decision/evidence tables (tiers, detector mapping, canary fields), not anti-rationalization or self-grading checklists.
- **No time-sensitive phrasing in instructions.** The dates in canary-pattern.md (2026-06-12 → 2026-07-12) are clearly worked examples, not "as of" claims.

## Recommendations

Prioritized:

1. **(MEDIUM, do first)** Convert the 9 reference/asset links in SKILL.md to `${CLAUDE_SKILL_DIR}/...` form. This is the only finding that affects correctness at runtime, since the skill executes from the target project root.
2. **(LOW)** Add a `## Contents` ToC to each of the 6 reference files over 100 lines to clear the validator warnings and cut consult cost.
3. **(LOW, optional)** Extend the description's exclusion clause to cover trivial single-file lint fixes (e.g. unused import), to close the 1/3 over-trigger.
4. **(INFO, optional)** Replace the restated degradation rule in SKILL.md:61 with a pointer to the detectors.md table to keep a single source of truth.

No structural rework, no security concerns, no validator errors. After fixes 1–2 the skill clears validation warning-free.
