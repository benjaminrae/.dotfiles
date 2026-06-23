# Per-Candidate Verification Workflow

This is the concrete procedure for running the reflection checklist on one candidate. It is mechanical enough that a 30+ candidate audit is feasible in one sitting. Apply it to every Tier 1 and Tier 2 candidate before locking in the tier.

## Inputs

From `candidates.json` (produced by [scripts/parse-intellij.py](../scripts/parse-intellij.py)) each candidate has:

| Field | Example |
|-------|---------|
| `id` | `com.example.foo.BarService#processOrder` |
| `type` | `class` / `method` / `field` |
| `file` | `core/src/main/java/com/example/foo/BarService.java` |
| `package` | `com.example.foo` |

From these, derive:

- `FQN` — for classes, the `id`; for methods/fields, the class portion of `id` (everything before `#`)
- `SIMPLE` — last segment of `FQN`
- `MEMBER` — for methods/fields, the part after `#`

## The mechanical procedure

Run the searches below. **Record the result of every one** in the candidate's report entry — even "0 hits". Skipping a search is a defect; it leaves the verdict unjustified.

### Step 1 — Plain reference search

```bash
# Simple name across the whole repo (excluding build artifacts and worktrees)
rg -n "\\b$SIMPLE\\b" --type java -g '!**/.worktrees/**' -g '!**/build/**'

# Same simple name in non-Java files (YAML, properties, XML, SQL, Liquibase, logback, conf)
rg -n "\\b$SIMPLE\\b" -g '*.yml' -g '*.yaml' -g '*.properties' -g '*.xml' -g '*.sql' -g '*.json' -g '*.conf' -g '!**/build/**'

# Fully-qualified name
rg -nF "$FQN" -g '!**/build/**'

# For methods/fields: the member name
rg -n "\\.$MEMBER\\b" --type java -g '!**/.worktrees/**' -g '!**/build/**'
```

Record: count of hits, locations of each hit, and which hits are "the declaration itself" vs "references".

### Step 2 — Published API contract

```bash
# Is the candidate's file annotated with @Schema, @Operation, or related?
rg -n "@(Schema|Operation|ApiResponse|RequestBody|Parameter|Tag)\b" "$FILE"

# Is the candidate referenced from anywhere annotated as API contract?
rg -nF "$SIMPLE" --type java -g '!**/build/**' | rg "@(Schema|ApiResponse|RequestBody|Parameter|Content|ArraySchema)"

# For enums: does the enclosing enum have @Schema(enumAsRef=true)?
# If yes, EVERY value is part of the published contract — reclassify all values as false positives.
```

For a `<SIMPLE>` that appears in a generated OpenAPI spec:

```bash
rg -nF "$SIMPLE" build/openapi/ src/main/resources/openapi* 2>/dev/null
```

### Step 3 — Spring string indirection

```bash
# @Qualifier and bean-name strings
rg -nF "\"$SIMPLE\"" --type java -g '!**/build/**' | rg -E "@(Qualifier|Bean|Component|Service|Repository)\(.*\"$SIMPLE\""

# @ConditionalOnProperty, @Profile, SpEL
rg -n "$SIMPLE" --type java -g '!**/build/**' | rg -E "@(Value|ConditionalOnProperty|Profile|PreAuthorize|PostAuthorize|Cacheable|EventListener|KafkaListener|RabbitListener|JmsListener|Scheduled|ConfigurationProperties)"
```

### Step 4 — Spring Data repository (special case for `JpaRepository`/`CrudRepository` methods)

If the candidate is a method on an interface that extends a Spring Data repository:

```bash
# Is the repository (the enclosing interface) injected and called?
rg -n "private final $FQN " --type java -g '!**/build/**'   # field declaration of the repo
rg -n "\\.${MEMBER}\\(" --type java -g '!**/build/**'         # invocations

# Is the method referenced via @Query("...") or @NamedQuery on a sibling class?
rg -n "@(Query|NamedQuery|NamedQueries)" "$FILE"
```

"No callers + no @Query reference + no JPQL hit" → Tier 1 candidate. Do NOT count "no impl found" as evidence — Spring Data synthesises implementations at runtime.

### Step 5 — Serialisation surfaces

```bash
# Is the candidate (or its enclosing class) used in a controller signature?
rg -nF "$SIMPLE" --type java -g '!**/build/**' | rg -E "(ResponseEntity<.*$SIMPLE|@RequestBody.*$SIMPLE|@ResponseBody.*$SIMPLE)"

# RestTemplate / WebClient usage of the type
rg -nF "$SIMPLE" --type java -g '!**/build/**' | rg -E "(restTemplate|webClient)\.[a-zA-Z]+\("

# Jackson @JsonProperty / @JsonAlias / @JsonSubTypes / @JsonTypeInfo on the field or class
rg -n "@(JsonProperty|JsonAlias|JsonSubTypes|JsonTypeInfo|JsonCreator|JsonValue)" "$FILE"

# JPA: is the enclosing class an @Entity?
rg -n "@(Entity|Embeddable|MappedSuperclass)" "$FILE"

# MapStruct: is the candidate referenced from any *Mapper interface?
rg -nF "$SIMPLE" --type java -g '*Mapper.java' -g '!**/build/**'
```

For a JPA `@Entity`: **never delete fields based on static analysis alone** — Hibernate reflects on every field. Cross-check the schema (Liquibase changelog or migration).

### Step 6 — Direct reflection

```bash
# Direct lookups by name
rg -nF "\"$SIMPLE\"" --type java -g '!**/build/**' | rg -E "(Class\.forName|getMethod|getDeclaredMethod|getField|getDeclaredField|MethodHandles)"

# ServiceLoader registration
find . -path '*/META-INF/services/*' -type f -exec grep -l "$FQN" {} \;

# AOP pointcut matching the candidate by package/name pattern
rg -nF "$SIMPLE" --type java -g '!**/build/**' | rg "@(Pointcut|Around|Before|After|AfterReturning|AfterThrowing)"
```

### Step 7 — Framework discovery

Check the candidate's `extends` / `implements` clauses against the list in [entry-points.md](entry-points.md#built-in-roots). If it extends a discovered supertype, the candidate is auto-wired by Spring or another framework regardless of explicit references.

```bash
# What does the candidate extend or implement?
rg -n "^public.*class.*$SIMPLE.*(extends|implements)" "$FILE"
rg -n "^public.*interface.*$SIMPLE.*extends" "$FILE"
```

### Step 8 — Build and infrastructure

```bash
# Mentions in Gradle scripts, Dockerfiles, CI config
rg -nF "$SIMPLE" build.gradle build.gradle.kts settings.gradle* 2>/dev/null
rg -nF "$FQN" Dockerfile* docker-compose*.yml 2>/dev/null
rg -nF "$SIMPLE" .github/ .gitlab-ci.yml Jenkinsfile* 2>/dev/null
```

## Tier decision

After running all 8 steps:

| Outcome | Tier |
|---------|------|
| Steps 1-8 all zero hits outside the declaration | **Tier 1 — Remove now** |
| Hits only from `src/test` and the test is dedicated to this candidate | **Tier 2 — Remove with tests** (see [Tier 2 verification recipe](#tier-2-verification-recipe) below) |
| Any hit in steps 2-8 that confirms the candidate is reachable but you cannot enumerate all callers | **Tier 3 — Canary** |
| Hits in step 2 (`@Schema` etc.) confirming the candidate is part of the published API contract | **False positive — verified live** |

## Tier 2 verification recipe

Tier 2 = production code referenced only by tests, where the tests exist solely to exercise the dead code.

For each production candidate that came back "zero main hits, N test hits":

```bash
# List the test files that mention the candidate
rg -lF "$SIMPLE" --type java -g 'src/test/**' -g '!**/build/**'
```

For each test file in that list, **read enough of the file to answer two questions**:

1. **Is the test dedicated to this candidate?** A test class whose name matches the candidate (`BarServiceTest` for `BarService`) and whose methods only exercise `BarService` is dedicated. A test that uses the candidate as one of many dependencies is shared fixture logic.
2. **Are there other production paths into the test?** If the test instantiates the candidate via a builder or fixture that other tests also use, the test stays even when the candidate goes — delete only the test-class-or-method that targets this candidate.

Decision rules:

| Test file character | Action |
|---------------------|--------|
| Dedicated test class (1:1 with candidate) | Delete the whole test class in the same commit as the production code |
| Test method inside a shared class, asserting behaviour of this candidate only | Delete the method only |
| Shared fixture/builder/helper class | Leave it — it's test infrastructure, out of scope |
| Test that exercises the candidate as a collaborator of something else | Out of scope — that test stays |

When in doubt, demote to Tier 3 (canary) rather than risk deleting useful test infrastructure.

## Batching the work

For an N-candidate audit, do the verification in this order:

1. **Group by file.** Candidates in the same file share many of the search results (especially Step 1). Verify a file's candidates in one pass.
2. **Group by archetype.** Repository methods (Step 4 dominant), Jackson DTO fields (Step 5 dominant), constants and enums (Steps 2 + 3) — knock out one archetype at a time.
3. **Process false-positive smells first.** Anything annotated `@Schema`, `@Entity`, or implementing a discovered supertype is fast to reclassify. Burn through those before spending time on hard cases.

When verifying via subagents (one per candidate), pass: the candidate `id`, the path to this file, and the path to `candidates.json`. The subagent runs the procedure and returns a structured evidence block.
