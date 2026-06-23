---
name: dead-code-audit
description: "Use when the user wants to know what code is safe to delete in a Java/Spring Boot/Gradle project, or audits it for dead or unused code, code cleanup, removing legacy code, unused classes or methods, dead endpoints, or canary deprecation. Produces a tiered removal report (delete now / delete with tests / instrument as canary) and optionally generates the deletion or instrumentation branch. Not for removing a single known class or non-JVM projects."
---

# Dead Code Audit

## Overview

This skill produces a project-wide dead code report for a Java/Spring Boot/Gradle codebase and, on confirmation, drives the follow-up action (delete or instrument). It is an **audit-and-triage** skill: static tools propose candidates, the skill applies Spring-aware judgement to verify them, and the deliverable is a Markdown report plus an optional follow-up branch.

**Scope rule.** Deletion candidates are `.java` source files only. Non-Java files (YAML, properties, XML, SQL, Liquibase changelogs, Dockerfiles, CI config, scripts) are never deleted by this skill, but they remain fully in scope as **evidence sources** — a class referenced only from a Liquibase changelog or logback config is live, and the only way to know is to search those files.

## Tiers

Every candidate is classified into exactly one tier. The wording in the report must never claim certainty beyond what static analysis and the reflection checklist support.

### Tier 1 — Remove now

Never referenced by production code, never referenced by test code, and has no hit on the full reflection checklist in [references/reflection-checklist.md](references/reflection-checklist.md). Safe to delete.

### Tier 2 — Remove with tests

Production code referenced **only** by test code, with no reflection-checklist hits. The tests are testing dead code; both the production code and the tests that exist solely to exercise it are candidates. Genuine test infrastructure (fixtures, builders, helpers in test source sets) is **out of scope entirely** — see [references/entry-points.md](references/entry-points.md).

### Tier 3 — Canary

Anything where static analysis cannot rule out usage: public methods on Spring entry points, REST endpoints possibly called by other services, code with partial reflection evidence, ambiguity of any kind. For these, **instrument rather than delete** using the canary pattern in [references/canary-pattern.md](references/canary-pattern.md).

## When to Use

- User asks to find dead code, unused code, or what is safe to delete
- Cleaning up legacy code before a refactor or upgrade
- Reviewing what a service still uses before retiring or merging it
- Following up on a previous audit (canary observation windows)

## When NOT to Use

- Project-specific lint findings on a single PR (use a normal review)
- Removing a known specific class (just delete it with tests as a normal change)
- Non-JVM projects (this skill assumes IntelliJ headless + Gradle + Spring)

## Workflow

### Preflight

1. Confirm the target is a Gradle Java project. Check for `build.gradle`/`build.gradle.kts` and a `src/main/java` tree at the root or in any module subdirectory listed in `settings.gradle*`. Refuse otherwise.
2. Check the working-tree state with `git status --porcelain`. The **audit phase is read-only** (it writes only the report file and the `.dead-code-audit/run/` output dir) and runs regardless. Record the state in the report header so reviewers know what was on disk at audit time. **The delete and canary phases refuse to run on a dirty tree** — that check happens later, not here.
3. Read the per-repo override file `dead-code-allowlist.txt` at the repo root if present. If absent, instruct the user once that they can create one (see [references/entry-points.md](references/entry-points.md)). Do not invent entries.
4. Read `dead-code-canaries.json` at the repo root if present, so the report can include canary status. If absent, the canary status section is empty.

### Detection

Primary detector: **IntelliJ headless inspections**, using the curated profile shipped at [assets/inspection-profile.xml](assets/inspection-profile.xml). See [references/detectors.md](references/detectors.md) for command variants (`idea`, `idea64`, `idea.sh`, macOS app bundle), JSON output parsing, and how to degrade gracefully when IntelliJ is unavailable.

Secondary detectors, merged into the same candidate list when available:

- **PMD via Gradle** with rules `UnusedPrivateMethod`, `UnusedPrivateField`, `UnusedLocalVariable`, `UnusedFormalParameter`.
- **`com.autonomousapps.dependency-analysis`** via `./gradlew buildHealth`, reported in a separate section (unused/misdeclared dependencies, not deletion candidates of `.java` files).

If IntelliJ is not on the machine, fall back to PMD + the skill's own checklist analysis, and **say so in the report header** so the reader knows the coverage is reduced.

The helper [scripts/run-audit.sh](scripts/run-audit.sh) wraps the detection commands; invoke it from the project root.

### Verification

For every Tier 1 and Tier 2 candidate, **work through the mechanical procedure in [references/verify-candidate.md](references/verify-candidate.md)** — it templates the 8-step checklist as concrete `rg`/`find` commands per candidate and tells you how to record evidence. The underlying checklist (what to look for and why) is in [references/reflection-checklist.md](references/reflection-checklist.md). For audits with more than ~6 candidates, dispatch one verification subagent per candidate using the prompt template in [references/subagent-template.md](references/subagent-template.md) and run them in parallel. The checklist covers:

- Plain string references to simple and fully-qualified names across the whole repo (including YAML, properties, Liquibase, logback, SQL, JPQL, test resources, docs)
- Spring string indirection: `@Qualifier`, `@ConditionalOnProperty`, SpEL in `@Value`/`@PreAuthorize`/`@Cacheable`, `@Profile`, bean names, listeners (`@EventListener`, `@KafkaListener`, etc.), `@Scheduled`, `@ConfigurationProperties`
- Serialisation surfaces: Jackson DTOs (reachable via controllers, `RestTemplate`/`WebClient`, messaging payloads), JPA entities, MapStruct mappers
- Direct reflection: `Class.forName`, `getMethod`, `getDeclaredField`, `MethodHandles`, `ServiceLoader`, AOP pointcut by name
- Framework discovery: `Converter`, `HealthIndicator`, `Filter`, `WebMvcConfigurer`, Liquibase custom changes, Flyway callbacks
- Build/infra references: Gradle build scripts, Dockerfiles, CI config, scripts referencing main classes

Any hit either **reclassifies the candidate as live** (recorded with the evidence in the report's false-positives section) or **demotes it to Tier 3** if the evidence is ambiguous.

Roots that are never deletion candidates — `main`, `@SpringBootApplication`, controller handler methods, scheduled jobs, messaging listeners, actuator beans, anything matched by the per-repo allowlist — are listed in [references/entry-points.md](references/entry-points.md). Honour them before classification.

### Reporting

Write the report to `dead-code-report.md` at the repo root (or a user-chosen path). The required structure is in [references/report-template.md](references/report-template.md). Highlights:

- **Summary table** with counts and estimated LOC per tier, count of unused dependencies, detection coverage note (IntelliJ available? PMD available?)
- **Per-tier sections** listing each candidate with file path, symbol, detectors that flagged it, checklist evidence, and a one-line tier justification
- **False positives section** — candidates flagged by detectors but verified live, with the evidence (this builds trust over time)
- **Canary status section** driven by `dead-code-canaries.json`: active canaries with days remaining and canaries ready for graduation review
- **"How to act on this" footer** — re-invoke the skill against the report to generate the deletion branch (Tier 1, Tier 2) or apply canary instrumentation (Tier 3)

Wording for Tier 1 must be "no usage found via static analysis and the full reflection checklist", **never** "guaranteed unused".

### Acting on the report

Only after the user has reviewed the report and explicitly asked to proceed:

**Delete branch (Tier 1 + Tier 2).**
0. **Stop if the working tree is dirty.** Ask the user to commit or stash first. This is the check the audit phase deferred.
1. Create a fresh branch off the repo's default branch using a worktree (see the repo's git-workflow conventions).
2. Delete files in clusters grouped by feature/package, **one logical commit per cluster**, so each commit is independently revertable. Never one mega-commit.
3. **Interface-method fanout**: when the candidate is a method on an `interface` (including `JpaRepository` and friends) or an `abstract` method on a base class, the same commit must:
   - Remove the declaration from the interface / abstract class
   - Remove the `@Override` from every concrete implementation in `src/main`
   - Remove the `@Override` from every test stub in `src/test` (e.g. `*Stub`, `*Fake`, `*Spy` types that implement the interface for tests)
   - Run `./gradlew compileJava compileTestJava` before committing — if any implementation is missed, compilation fails fast.
   Group all such fanout into one commit per interface-method cluster, not one commit per file.
4. For Tier 2, delete the production code and the tests that exist solely to exercise it in the same commit; the commit message must call this out.
5. After each commit, run `./gradlew compileJava compileTestJava` and the test suite. If anything breaks, revert that commit and demote the affected candidates to Tier 3.
6. Skip anything under generated sources, vendored code, or matched by the allowlist — these should never have reached this step, but check defensively.

**Canary branch (Tier 3).**
0. **Stop if the working tree is dirty.** Same rule as the delete branch.
1. For each candidate, apply the canary instrumentation described in [references/canary-pattern.md](references/canary-pattern.md): `@Deprecated`, Javadoc note referencing the audit, Micrometer counter `deadcode.canary.invocations` tagged by class and method (fall back to a single `WARN` line prefixed `DEADCODE_CANARY` if Micrometer is not on the classpath).
2. Append a record to `dead-code-canaries.json`: candidate identifier, date instrumented, observation window in days (default 30, configurable per candidate).
3. For REST endpoints, the report MUST state that traffic must be checked against `http_server_requests` metrics or access logs before graduation, and the skill must ask the user whether they can pull that data. **Never graduate an endpoint on code canary evidence alone.**

**Canary follow-up runs.**
On subsequent invocations, the skill reads `dead-code-canaries.json` and:
- Lists active canaries with days remaining
- Lists canaries whose observation window has elapsed
- For each elapsed canary, prompts the user to confirm zero invocations from metrics/logs (and traffic data for endpoints)
- Confirmed-zero canaries graduate to **Tier 1 in the next report**

## Safety Rules

| Rule | Why |
|------|-----|
| Audit phase runs on a dirty tree (read-only); delete/canary phases refuse on a dirty tree | Audit is informational; only the action phases risk clobbering in-progress work |
| Never delete without an explicit user request after report review | The report is informational; deletion is a separate decision |
| Deletions must compile and tests must pass after every commit | Each commit is independently revertable |
| Group deletion commits by feature/package, not in one mega-commit | Keep blast radius narrow |
| Never instrument or delete in generated sources, vendored code, or allowlisted paths | These are not project-owned source |
| Never delete a non-Java file as part of this skill | Out of scope; non-Java files are evidence only |
| Tier 1 wording must say "no usage found", not "guaranteed unused" | Match the evidence; static analysis has limits |
| REST endpoints never graduate on code-canary evidence alone | Other services may call them; traffic data is required |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Treating Jackson DTOs as unused because nothing calls their getters/setters directly | Check controller signatures, `RestTemplate`/`WebClient`, messaging payloads — Jackson uses reflection |
| Treating JPA entity fields as unused because no Java code reads them | Hibernate reflects on every field; verify with schema/migration usage |
| Deleting tests because the production code is dead, when the test contains shared fixture logic used elsewhere | Tier 2 deletes tests **only** if they exist solely to exercise the dead code |
| Generating one giant deletion commit | One logical commit per cluster — independently revertable |
| Graduating a REST endpoint canary from invocation counter alone | Cross-check `http_server_requests` metrics or access logs |
| Skipping the per-repo allowlist on first run | Prompt the user to create `dead-code-allowlist.txt`; do not invent entries |
| Including non-Java files as deletion candidates | Out of scope — non-Java files are evidence only |
| Refusing to audit on a dirty tree | Audit is read-only — run it and surface the tree state in the report header. Only refuse on dirty tree at the delete/canary step |
