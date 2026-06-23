# Report Template

The report is written to `dead-code-report.md` at the repo root unless the user specifies another path. The structure below is required — sections may be empty (state "(none)") but must be present so reviewers know what was checked.

## Required structure

```markdown
# Dead Code Audit Report

- **Project**: <repo name>
- **Branch**: <current branch>
- **Commit**: <short SHA>
- **Generated**: <ISO date, UTC>
- **Detector coverage**: <one line from detectors.md graceful-degradation table>
- **Allowlist**: <`dead-code-allowlist.txt` present? entry count, or "not present">

## Summary

| Tier | Candidates | Estimated LOC |
|------|------------|---------------|
| Tier 1 — Remove now             | N |  M |
| Tier 2 — Remove with tests      | N |  M |
| Tier 3 — Canary                 | N |  M |
| **False positives (verified live)** | N | — |
| **Active canaries**             | N | — |
| **Canaries ready for review**   | N | — |
| **Unused / misdeclared dependencies** | N | — |

## Tier 1 — Remove now

> Wording: "no usage found via static analysis and the full reflection checklist". Never "guaranteed unused".

### `<package or feature cluster>`

- **`com.example.foo.BarService`** (`src/main/java/com/example/foo/BarService.java`)
  - Detectors: IntelliJ (`unused`), PMD (`UnusedPrivateMethod` for `helper()`)
  - Checklist:
    - Plain string search — 0 hits outside declaration
    - Spring indirection — no `@Qualifier`/SpEL/`@ConditionalOnProperty` hits
    - Serialisation — not a DTO, not an entity
    - Direct reflection — no `Class.forName`/`getMethod` hits
    - Framework discovery — does not extend a discovered supertype
    - Build/infra — no Gradle/Docker/CI references
  - Verdict: no usage found via static analysis and the full reflection checklist.

(continue per cluster)

## Tier 2 — Remove with tests

> Production code referenced only by tests; tests are testing dead code.

### `<package or feature cluster>`

- **`com.example.foo.LegacyMapper`** (`src/main/java/com/example/foo/LegacyMapper.java`)
  - Detectors: IntelliJ (`unused`)
  - Test references:
    - `src/test/java/com/example/foo/LegacyMapperTest.java` — entire class
  - Checklist: (same shape as Tier 1)
  - Verdict: production code referenced only by `LegacyMapperTest`; both are deletion candidates. Test contains no shared fixture logic used elsewhere.

## Tier 3 — Canary

> Static analysis could not rule out usage; instrument and observe.

### `<package or feature cluster>`

- **`com.example.foo.OrderService#processLegacyOrder`** (`src/main/java/com/example/foo/OrderService.java`)
  - Detectors: IntelliJ (`unused`)
  - Checklist findings that block Tier 1:
    - `@Qualifier("legacyOrderProcessor")` referenced in `application-staging.yml` — bean name partially matches; cannot rule out reflective resolution
  - Proposed canary:
    - `@Deprecated(forRemoval = true)` + Javadoc note
    - Counter `deadcode.canary.invocations{class=com.example.foo.OrderService,method=processLegacyOrder}`
    - Observation window: 30 days
    - Endpoint: no
  - Notes: re-check `@Qualifier` resolution with Spring's `BeanFactory.getBeanNamesForType` if traffic data unavailable.

## False positives (verified live)

> Candidates flagged by detectors but confirmed in use during the checklist phase. Listed here so the team builds trust in the audit.

- **`com.example.foo.JsonView`** — flagged by IntelliJ `unused`; referenced from `application.yml` Jackson configuration (`spring.jackson.visibility`).
- **`com.example.health.LiquibaseHealthIndicator`** — flagged by PMD; implements `HealthIndicator`, auto-discovered by Spring Boot Actuator.

## Canary status

> Driven by `dead-code-canaries.json`. Active and ready-for-review entries surfaced separately.

### Active

| Candidate | Instrumented | Window | Days remaining | Endpoint? |
|-----------|--------------|--------|----------------|-----------|
| `com.example.foo.OrderService#processLegacyOrder` | 2026-06-12 | 30d | 18 | no |

### Ready for review

| Candidate | Instrumented | Window | Endpoint? | Action |
|-----------|--------------|--------|-----------|--------|
| `com.example.bar.RetiredEndpointController#oldRoute` | 2026-05-10 | 30d | yes | Confirm zero traffic in `http_server_requests` and access logs before graduation |

## Dependency hygiene

> Output from `./gradlew buildHealth` summarised below. Not deletion candidates of `.java` files.

(verbatim summary)

## How to act on this report

- **Tier 1 + Tier 2**: re-invoke the skill against this report to generate a deletion branch (one logical commit per cluster, compile and tests run after each commit).
- **Tier 3**: re-invoke the skill to generate a canary instrumentation branch. Each canary appends to `dead-code-canaries.json`.
- **Canaries ready for review**: confirm zero invocations (and zero traffic for endpoints) before the next audit; the next report will promote confirmed canaries to Tier 1.
```

## Style rules

- Tier 1 must never use absolute language ("guaranteed unused", "definitely dead"). Use "no usage found via static analysis and the full reflection checklist".
- Tier 3 must always list the specific checklist findings that prevented Tier 1 classification.
- The false-positives section is required even if empty — its presence signals the audit ran the verification step.
- Per-candidate evidence must be specific enough that a reviewer can re-run the same searches and reach the same conclusion. Vague evidence ("looks unused") is a defect.
- Estimated LOC is the sum of non-blank, non-comment lines in the candidate files. Approximate is fine; do not block the report on exact counts.
