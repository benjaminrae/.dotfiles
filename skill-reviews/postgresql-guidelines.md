# Skill Review: postgresql-guidelines

A well-scoped, validator-clean PostgreSQL conventions reference whose main weaknesses are duplication between SKILL.md and conventions-reference.md, a heavy MUST/NEVER density, and team-policy rules stated without their inverse boundaries. **Overall verdict: PASS WITH WARNINGS** — ships safely, but conciseness and over-prescription dimensions need attention.

## Validator output

`validate_skill` ran successfully and returned a clean result:

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":150,"description_chars":198,"reference_files":0}}
```

- **Errors:** none → no FAIL on the deterministic floor.
- **Warnings:** none.
- SKILL.md is 150 lines (well under the 500-line limit).
- Description is 198 chars (within 1–1024).
- Manual floor cross-check:
  - `name: postgresql-guidelines` (SKILL.md:2) — lowercase + hyphens, matches dir, ≤64 chars, no "claude"/"anthropic". PASS.
  - Description is third person, single sentence, no XML. PASS.
  - `conventions-reference.md` is referenced from SKILL.md:10 — one level deep. PASS.
  - **No evals present.** The directory contains only `SKILL.md` and `conventions-reference.md` (confirmed via `ls`). The Step-1 floor calls for ≥3 evals; the validator does not gate on this, but it is a gap. `"reference_files":0` in stats also indicates the validator did not register the reference file under its formal reference-file mechanism — worth confirming the link is discoverable.

## Trigger probe

`test_triggers` was invoked with 6 should-trigger and 4 near-miss queries (3 runs each). **Every run failed with an infrastructure error** (`infra_errors: 30/30`, `summary.passed: 0, failed: 0`, `total_cost_usd: 3` — the budget cap was hit while only infra failures accrued). This yields **no usable live trigger signal**; trigger_rate is 0 across the board purely because no probe session completed, not because the description failed.

Manual substitute analysis of the description (SKILL.md:3):

> `Use when writing or reviewing PostgreSQL code — schema design, migrations, queries, naming conventions, slow queries, cascade deletes, enum migrations, or naming inconsistencies in database objects.`

- **Should-trigger coverage:** strong. Concrete nouns (migrations, slow queries, cascade deletes, enum migrations, naming inconsistencies) map directly to user phrasings. "PostgreSQL" anchors the domain explicitly. Key use case ("writing or reviewing PostgreSQL code") is first.
- **Near-miss exclusion:** weaker. The description names no exclusions. "PostgreSQL" is the only guard against firing on MySQL/MongoDB/SQLite or general code-review requests. A prompt like "review my MySQL schema for naming issues" shares the conceptual surface (schema, naming) and could plausibly over-trigger, since most body content is generic relational-DB convention. No negative boundary is present.
- **No workflow steps** embedded in the description. Good.

Recommend re-running `test_triggers` once the harness infra is healthy before trusting any trigger verdict.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|-----------|--------|-------|-------------|
| Validator floor | PASS | Clean: 0 errors, 0 warnings, 150 lines, 198-char desc | None; add ≥3 evals to satisfy Step-1 floor |
| Triggers | WARN | No live data (30/30 infra errors). Strong positives but zero stated near-miss exclusion; "PostgreSQL" is the only guard | Add an explicit negative boundary; re-run test_triggers when infra is healthy |
| Structure | WARN | SKILL.md Writing/Review/Quick-Ref sections and conventions-reference.md restate the same facts 2–5× each | Make SKILL.md the canonical decision surface, demote conventions-reference.md to examples-only |
| Over-prescription | WARN | High NEVER/ALWAYS/Team-policy density; rules stated without inverse boundaries; "Flag X" lists read as exhaustive enforcement checklists | Soften absolutes, state the boundary of each "NEVER" |
| Conciseness | WARN | Explains Postgres facts Claude already knows (ENUM drawbacks, identifier folding, EXISTS-vs-COUNT rationale); recurring token cost from duplication | Trim domain education; keep only team-specific deviations from defaults |
| Workflow completeness | PASS | Reference scope is appropriate; writing-vs-review split is sensible and well-organized | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance scoring, no "Red Flags — STOP" blocks | None |
| Supply chain | PASS | No scripts, executables, or network calls in the bundle | None |
| Hygiene | WARN | Hardcoded date literal in an example; "team policy" stated without an adopting-team config note; reference not registered as a formal reference file | See findings |

## Findings

Ranked by severity.

### 1. (WARN, highest impact) Pervasive duplication between SKILL.md and conventions-reference.md — each fact lives in 2–5 places
The two files restate the same rules:
- Identifier folding: SKILL.md:20, conventions-reference.md:18, conventions-reference.md:35 all explain "PostgreSQL folds unquoted identifiers to lowercase / camelCase is source-readability only."
- Constraint/index naming patterns appear at SKILL.md:27–34, the table at conventions-reference.md:55–63, **and** the Anti-Patterns table at SKILL.md:148.
- The CASCADE rule appears at SKILL.md:12 (hard rule), SKILL.md:69 (Constraints), SKILL.md:117 (Review Mode), SKILL.md:141 (Anti-Patterns table), and conventions-reference.md:228–232 — **five** statements of one rule.
- UPSERT trigger semantics: SKILL.md:73–74, SKILL.md:121–122, SKILL.md:142, conventions-reference.md:209–226.

The skill-craft principle is "each fact in one place." This is the dominant issue: it inflates token cost on every load and creates drift risk (a future edit to one copy leaves the others stale). **Fix:** pick one canonical home per fact — SKILL.md holds the decision rules (one line each) plus the single Anti-Patterns quick-reference; conventions-reference.md holds *only* worked SQL examples and rationale, not a re-listing of rules.

### 2. (WARN) Over-prescription: absolute mandates without boundaries
- SKILL.md:12 `**Hard rule (team policy):** NEVER use ON DELETE CASCADE` and SKILL.md:69 `**NEVER** use ON DELETE CASCADE`. The body at SKILL.md:12 does explain the alternative, but the bare repetitions don't.
- SKILL.md:78 `**Always store and transmit timestamps in UTC**`, SKILL.md:60 `Write **ALL keywords in UPPER CASE**`, conventions-reference.md:5 BCNF "as a baseline."
- The Review-Mode "Flag X" lists (SKILL.md:88–130) read as an exhaustive enforcement checklist applied to *every* review: roughly 6 ALWAYS/NEVER-class absolutes plus ~20 "Flag …" imperatives. Dense for what is fundamentally a guidelines reference.

**Fix:** state the boundary alongside each hard rule ("NEVER `ON DELETE CASCADE`; for cleanup of dependent rows, delete explicitly in a transaction in app code"). Model the other absolutes on the existing CASCADE explanation at SKILL.md:12 and drop the bare repetitions.

### 3. (WARN) Conciseness: educational prose about PostgreSQL Claude already knows
Scrutinized heavily per the brief for a reference skill. Several passages teach generic Postgres rather than team deviations:
- conventions-reference.md:187–193 enumerates ENUM drawbacks ("Cannot rename existing values… Not standard SQL…") — standard Postgres knowledge; only the team rule ("reference table with short PK") is team-specific.
- conventions-reference.md:78–113 walks through COUNT(*) vs EXISTS with good/bad SQL and explanatory comments ("scans and counts every matching row"). The *rule* is team policy; the *rationale* is generic SQL theory.
- SKILL.md:136–149 Anti-Patterns table embeds explanations ("stops at first match", "read top-to-bottom, easier to debug") that restate well-known reasoning.
- conventions-reference.md:1–8 reads as documentation prose written *about* the domain rather than directives *to* Claude.

**Fix:** keep the team's chosen convention plus a one-line "why we picked it"; cut the tutorial-grade explanation of why Postgres ENUM/COUNT behave as they do.

### 4. (WARN) "Team policy" presented without an adopting-team config note
"Team policy" rules (UPSERT, CASCADE) are correctly labeled (SKILL.md:73, SKILL.md:117, conventions-reference.md:226), but the skill ships via dotfiles to potentially many contexts. There is no note that these are *this team's* opinionated choices. Several un-tagged rules (UTC, UPPER CASE keywords, leading commas, BCNF) are equally opinionated, so a reader cannot reliably distinguish Postgres fact from local preference. **Fix:** add a one-line Overview note that style/policy rules reflect a specific team convention.

### 5. (WARN, minor / hygiene) Time-sensitive and config-sensitive literals
- conventions-reference.md:173 `WHERE ua.createdAt >= '2024-01-01'` — a hardcoded date in an illustrative query; harmless but a reader may infer significance. Prefer a symbolic placeholder.
- No PG version numbers are hardcoded as claims (`gen_random_uuid()` at SKILL.md:24 is broadly available), so no stale-version risk. Good.

### 6. (INFO) Reference file not registered; no evals
- `validate_skill` reported `"reference_files":0` despite conventions-reference.md being linked at SKILL.md:10. The plain-markdown link works for a reading agent, but confirm it is the intended mechanism.
- No eval files exist (Step-1 floor wants ≥3). Add cases covering: a migration with `ON DELETE CASCADE` (should flag), an uppercase constraint name, a `COUNT(*)` existence check, and at least one near-miss (MySQL/general review) that should *not* invoke the skill.

## Recommendations

Prioritized:

1. **De-duplicate (highest ROI).** One canonical home per rule: SKILL.md = terse decision rules + the single Anti-Patterns quick-reference; conventions-reference.md = worked SQL examples only. Removes the 5×-CASCADE / 3×-naming / 4×-UPSERT repetition and the recurring token cost.
2. **Add inverse boundaries to every hard rule.** Convert bare `NEVER`/`Always` into "X; when you need the underlying behaviour, do Y instead" — model on SKILL.md:12.
3. **Cut generic Postgres tutorials.** Keep team-specific conventions + one-line rationale; remove standard-knowledge explanations of ENUM/COUNT/EXISTS behaviour.
4. **Add a "these are team conventions" note** in the Overview so adopters can tell policy from Postgres fact.
5. **Re-run `test_triggers` once infra is healthy** and add an explicit near-miss exclusion to the description (PostgreSQL-specific, not other databases or general code review).
6. **Add ≥3 evals** to meet the Step-1 floor, including at least one negative.
7. **Replace the hardcoded `'2024-01-01'`** example literal with a symbolic placeholder.
