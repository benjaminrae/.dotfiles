# Skill Review: java-conventions

A clean, short reference skill whose content is mostly inert restatement of Java/Spring knowledge Claude already has — verdict **WARN**: validator passes and triggers are well-scoped, but it ships zero evals, carries team-specific rules that read as generic, and is a strong candidate for CLAUDE.md rather than a skill.

## Validator output

Ran `mcp__plugin_oberskills_skill-eval__validate_skill` on the directory.

```json
{"valid":true,"errors":[],"warnings":[],"info":[],
 "stats":{"skill_md_lines":51,"description_chars":130,"reference_files":0}}
```

- **No errors, no warnings, no info.** Deterministic floor: **PASS**.
- `name: java-conventions` (line 2) is lowercase + hyphen, matches dir, ≤64 chars, no `claude`/`anthropic`. OK.
- `description` 130 chars, third person, no XML (line 3). OK.
- SKILL.md is 51 lines (<500), single file, 0 reference files — no TOC needed. OK.
- **Eval gap:** the skill-craft methodology expects ≥3 evals. There is no `evals/` directory and `reference_files:0`. The validator does not gate on this, but the review methodology does. **This is the one hard floor miss.**

## Trigger probe

`mcp__plugin_oberskills_skill-eval__test_triggers` was attempted twice (11-query set at 3 runs, then a reduced 5-query set at 2 runs). **Every probe returned an infra error** — 33/33 then 10/10 sessions failed to spawn; `total_cost_usd` hit the cap with `passed:0, failed:0, infra_errors:33`. No trigger signal could be obtained from the harness in this environment. Falling back to manual analysis of the description.

Description under test (line 3):
`Use when writing or reviewing Java/Spring Boot code — JPA mappings, Clean Architecture, migration consistency, and Spring patterns`

Manual judgement of likely behaviour:

| Query | Expected | Manual assessment |
|---|---|---|
| "Adding a field to the Order JPA entity, what to update?" | trigger | Likely — "JPA" + "entity" are concrete nouns in the description |
| "Spring Boot REST controller with a PUT endpoint" | trigger | Likely — "Spring Boot code" + "Spring patterns" |
| "Flyway migration adding a column, does my entity match?" | trigger | Likely — "migration consistency" is named |
| "Map this DTO to a JPA entity in my Spring app" | trigger | Likely — "JPA mappings" named |
| "PUT or PATCH for partial updates?" | trigger | Borderline — HTTP-method content is in the body (lines 48-51) but NOT surfaced in the description; a bare REST-semantics question with no "Java/Spring" cue may miss |
| "General code review of my PR" | no trigger | Correctly excluded — description is language-gated to Java/Spring |
| "Review this Python pipeline" / "React component" / "Go test" / "TypeScript refactor" | no trigger | Correctly excluded — non-Java languages named, description is Java-gated |

Near-miss exclusion looks **strong**: the description's explicit "Java/Spring Boot" gate is the main thing keeping general-code-review and other-language queries out. The one weak spot is that **HTTP method semantics (PUT/PATCH) is body content with no description hook**, so a pure REST-semantics question without a Java cue may not fire. Trigger dimension graded on description text only (harness unavailable).

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | WARN | Validator clean, but **0 evals** vs the ≥3 expected by the methodology | Add ≥3 evals (entity-field change, migration/entity drift, layer-skip review) |
| Triggers | PASS | Well-scoped, language-gated, near-misses excluded; HTTP-method content not surfaced in description | Optionally add "REST PUT/PATCH semantics" cue to description |
| Structure | PASS | Single file, each topic in one place, point-of-decision checklists | None |
| Over-prescription | WARN | "Update ALL" (line 35), "do not leave ... out of sync" (line 36), "do not leave them divergent" (line 46) — imperative scolding; rote numbered lists where a sentence suffices | Soften to guidance; collapse rote checklists |
| Conciseness | FAIL | Most content restates Java/Spring fundamentals Claude already knows (Clean Architecture layering, PUT vs PATCH, "no JPA annotations in DTOs"); near-zero team-specific signal | Cut generic knowledge; keep only what is non-obvious or team-specific |
| Workflow completeness | PASS | Appropriately scoped as reference; no half-built procedure | None |
| Banned constructs | PASS | No anti-rationalization tables, no self-assessed compliance, no "Red Flags / STOP" blocks | None |
| Supply chain | PASS | No scripts, no executables, no network calls | None |
| Hygiene | WARN | `./gradlew compileJava` (line 43) assumes Gradle (hedged with "or the project's build tool"); no README/CHANGELOG (good) | Keep build-tool hedge; otherwise fine |

## Findings

### 1. (High) Content is mostly generic Java/Spring knowledge — low marginal value over the base model
**Conciseness — FAIL.** A conventions skill earns its tokens by encoding *team-specific, non-obvious* decisions. Almost every line here is something Claude already does by default:

- Line 23: `Controllers -> Services -> Repositories (never skip layers)` — textbook layered architecture.
- Line 25: `No JPA annotations in DTOs, no HTTP annotations in services` — standard separation of concerns.
- Line 50: `Verify PUT methods require all fields (full resource replacement) and PATCH methods accept partial bodies` — this is the literal HTTP spec definition of PUT/PATCH, written *about* the domain rather than telling Claude anything it lacks.

This content costs context tokens on every invocation while adding little the base model wouldn't produce. The genuinely useful, *project-specific* parts (the JPA modification checklist at lines 27-36 and the migration/entity reconciliation at lines 38-46) are valuable precisely because they encode a *habit* — "when you touch an entity, sweep repositories/services/DTOs/tests." Keep those; cut the encyclopedia entries.

**Fix:** Reduce to the non-obvious rules. If the team has actual conventions (specific base classes, a mapper library choice, a migration tool, naming rules, a forbidden pattern), state those concretely. If there are none beyond "follow standard Spring practice," the skill mostly should not exist.

### 2. (High) No evals shipped
**Validator floor — WARN (methodology miss).** `reference_files:0` and there is no `evals/` directory. The skill-craft floor expects ≥3 evals so regressions in triggering/behaviour are catchable. Without them this skill is untested.

**Fix:** Add three evals, e.g. (a) "add a `status` field to the `Order` entity" → asserts the response checks repositories/services/DTOs/tests; (b) "here's a migration adding a column, the entity wasn't updated" → asserts it flags the drift; (c) a controller that calls a repository directly → asserts it flags the skipped service layer.

### 3. (Medium) Should this be CLAUDE.md content instead of a skill?
These are **always-relevant conventions** for any Java/Spring work in the team's repos, not a discrete procedure invoked occasionally. Always-on conventions are a classic CLAUDE.md fit (project memory), whereas skills shine for episodic, triggered workflows. The two checklists (JPA modification, migration consistency) are borderline-procedural and could justify a skill, but the architecture/HTTP-semantics prose is pure standing guidance.

**Fix:** Move the layering rules and PUT/PATCH semantics to the project's `CLAUDE.md`. Keep a skill *only* if the two checklists are substantial team-specific procedures worth lazy-loading; otherwise fold the whole thing into CLAUDE.md.

### 4. (Medium) Imperative scolding / over-prescription
**Over-prescription — WARN.**
- Line 35: `5. Update ALL of the above when changing entity fields`
- Line 36: `If any of these are missed, reconcile them before proceeding — do not leave repositories, services, DTOs, or tests out of sync with the entity.`
- Line 46: `... reconcile the entity and migration so both agree before proceeding — do not leave them divergent.`

The "do not leave ... out of sync / divergent" clauses are anti-laziness phrasing — they restate the preceding instruction in a scolding register without adding information. The numbered "checklist" at lines 29-34 also reads as rote where a single sentence ("when you change an entity field, sweep its repositories, services, DTOs, and tests") conveys the same thing.

**Fix:** Drop the "do not leave..." trailers; the positive instruction already covers it. Collapse the numbered list into a sentence unless the ordering is load-bearing (it isn't).

### 5. (Low) HTTP-method content not surfaced in the trigger description
**Triggers — PASS, minor gap.** Lines 48-51 cover PUT/PATCH semantics and OpenAPI matching, but the description (line 3) lists only "JPA mappings, Clean Architecture, migration consistency, and Spring patterns." A user asking purely about REST verb semantics, with no JPA/Spring cue, may not trigger the skill even though it has relevant content.

**Fix:** If HTTP-method semantics is a real use case, add a short cue ("REST PUT/PATCH semantics") to the description; otherwise accept that "Spring patterns" loosely covers it.

### 6. (Low) Build-tool assumption
**Hygiene — WARN (already mitigated).** Line 43: `Run ./gradlew compileJava (or the project's build tool)`. The Gradle assumption is hedged, which is the right call. No action needed beyond keeping the hedge.

## Recommendations

Prioritized:

1. **Decide skill-vs-CLAUDE.md (highest leverage).** This is always-on conventions content. Move the architecture-layering and PUT/PATCH guidance into the project `CLAUDE.md`. Retain a skill only if the JPA-modification and migration-consistency checklists are genuinely team-specific procedures worth on-demand loading.
2. **Cut generic knowledge.** Remove lines that restate Java/Spring fundamentals (layered architecture, separation of DTOs/entities, the HTTP spec definition of PUT/PATCH). Keep only non-obvious, team-specific rules. If little survives, that confirms #1.
3. **Add ≥3 evals** covering entity-field-change sweep, migration/entity drift detection, and layer-skip review — the only way to lock in the behaviour that justifies a skill.
4. **De-scold the prose.** Delete the "do not leave ... out of sync / divergent" trailers (lines 36, 46) and collapse the rote numbered list (lines 29-34) into a sentence.
5. **(Optional) Surface HTTP-method semantics** in the description if it's a real trigger case.
