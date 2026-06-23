# Canary Pattern

Tier 3 candidates are instrumented rather than deleted. The canary pattern records whether the code is invoked in production over an observation window. If no invocations are seen, the candidate graduates to Tier 1 in the next audit.

## Instrumentation Recipe

For each Tier 3 candidate:

### 1. Annotate

Add `@Deprecated` and a Javadoc note that references this audit. Keep the note short and unambiguous; reviewers should be able to find the audit from the symbol alone.

```java
/**
 * Dead-code canary instrumented {@code 2026-06-12}. See
 * {@code dead-code-report.md} for the audit. If no invocations are observed
 * by {@code 2026-07-12}, this is a candidate for deletion.
 */
@Deprecated(since = "dead-code-audit", forRemoval = true)
public OrderResult processLegacyOrder(LegacyOrder order) {
    ...
}
```

`forRemoval = true` is intentional: it makes call sites visible at compile time, which is useful evidence on its own.

### 2. Inject the invocation tracker

The tracker is **the first line of the method body** — before any other logic, including null checks. It must not throw and must not measurably affect latency.

**Preferred: Micrometer counter.** If `io.micrometer.core` is on the runtime classpath:

```java
private static final Counter CANARY = Metrics.counter(
    "deadcode.canary.invocations",
    "class", "com.example.foo.OrderService",
    "method", "processLegacyOrder"
);

public OrderResult processLegacyOrder(LegacyOrder order) {
    CANARY.increment();
    // ... existing logic unchanged
}
```

`Metrics.counter(...)` resolves against the global registry. If the project uses a registry bean (`MeterRegistry`), prefer constructor injection; for static utility methods or where injection is not possible, the global registry is acceptable for instrumentation that lives only for the observation window.

The counter name is **always** `deadcode.canary.invocations`. Tags:

| Tag | Value |
|-----|-------|
| `class` | Fully-qualified class name |
| `method` | Method name (no parameter signature) |

Do not add per-call tags (parameter values, user IDs, etc.) — cardinality must stay bounded.

**Fallback: WARN log.** If Micrometer is not on the classpath, emit a single `WARN` line with a stable prefix. The prefix is `DEADCODE_CANARY` so logs can be grepped/aggregated.

```java
private static final Logger LOG = LoggerFactory.getLogger(OrderService.class);

public OrderResult processLegacyOrder(LegacyOrder order) {
    LOG.warn("DEADCODE_CANARY class=com.example.foo.OrderService method=processLegacyOrder");
    // ... existing logic unchanged
}
```

Use **WARN** so the line clears the default log threshold in production (most services suppress `INFO` from non-allowlisted packages).

### 3. Record the candidate in the manifest

Append an entry to `dead-code-canaries.json` at the repo root:

```json
{
  "version": 1,
  "canaries": [
    {
      "id": "com.example.foo.OrderService#processLegacyOrder",
      "file": "src/main/java/com/example/foo/OrderService.java",
      "kind": "method",
      "instrumentedOn": "2026-06-12",
      "observationDays": 30,
      "isEndpoint": false,
      "notes": "Flagged by IntelliJ; reflection checklist inconclusive — possible @Qualifier hit in config"
    }
  ]
}
```

| Field | Meaning |
|-------|---------|
| `id` | Stable identifier. `<FQN>` for classes, `<FQN>#<method>` for methods, `<FQN>#<field>` for fields |
| `file` | Path from repo root to the source file |
| `kind` | `class`, `method`, or `field` |
| `instrumentedOn` | ISO date (UTC) the canary was added |
| `observationDays` | Days to observe before graduation review (default 30) |
| `isEndpoint` | `true` for REST handler methods — these require traffic data, not just code invocations, before graduation |
| `notes` | Free text explaining why this is Tier 3 not Tier 1 |

The manifest must be valid JSON. The skill rewrites it via load-modify-write rather than text patching.

## Observation Window

Default observation window: **30 days**. The user may override per-candidate by editing the `observationDays` field before merging the canary branch. Reasonable values:

- Background jobs / scheduled tasks: at least one full schedule cycle plus a margin (e.g. weekly job → 14+ days)
- User-facing endpoints: 30 days minimum; longer if the path is plausibly seasonal (billing, reporting)
- Anything called by another internal service: 30 days **plus** a traffic-data check

## Graduation Review

On subsequent audit runs:

1. Load `dead-code-canaries.json`.
2. For each entry, compute `daysElapsed = today - instrumentedOn`.
3. Status:
   - `daysElapsed < observationDays` → **active**, surface days remaining
   - `daysElapsed >= observationDays` → **ready for review**
4. For each ready entry, prompt the user to confirm:
   - "Has the Micrometer counter `deadcode.canary.invocations` with `class=<X> method=<Y>` reported zero invocations across the observation window?"
   - For `isEndpoint: true`, additionally: "Has `http_server_requests` (or access logs) for the corresponding route shown zero traffic? **Do not graduate on counter evidence alone.**"
5. Confirmed-zero → next audit promotes the candidate to Tier 1.
6. Non-zero invocations → leave the canary in place, update `notes` with the observed call sites, and consider rolling the candidate back from Tier 3 to live.

## Endpoint Special Case

For `isEndpoint: true` candidates, the skill MUST ask the user before generating the canary branch whether they have access to:

- `http_server_requests` Micrometer metrics for the relevant URI
- Access logs (ingress controller, ALB, nginx) covering the observation window
- Distributed traces showing inbound calls

If none of these are available, the skill warns: "Without traffic data this endpoint cannot graduate from canary safely. Consider extending `observationDays` or arranging traffic data access before instrumenting." Then asks for confirmation to proceed anyway.

## Removing Canaries

When the user accepts a graduation, the next deletion branch:

1. Removes the `@Deprecated` annotation, the canary counter/log line, and the imports they introduced
2. Removes the file entirely (this is the Tier 1 deletion in the new report)
3. Removes the matching entry from `dead-code-canaries.json`
4. Mentions the canary observation result in the commit message: "Graduated dead-code canary: 0 invocations over 30 days from 2026-06-12 to 2026-07-12."
