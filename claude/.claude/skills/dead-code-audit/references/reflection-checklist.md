# Reflection and String-Reference Checklist

Work through this checklist for **every Tier 1 and Tier 2 candidate** before locking in the tier. Any hit either reclassifies the candidate as live (record evidence in the report's false-positives section) or demotes it to Tier 3 if the evidence is ambiguous.

Search patterns use ripgrep (`rg`) syntax. The candidate's **simple name** and **fully qualified name** must both be searched.

## 1. Plain string references (whole repo)

For a class `com.example.foo.BarService`:

```bash
rg -nF "BarService"            # simple name
rg -nF "com.example.foo.BarService"  # FQN
rg -nF "com/example/foo/BarService"  # path form
```

Locations to check explicitly (do not limit to `.java`):

- `src/**/resources/**/*.yml`, `*.yaml`, `*.properties`
- `src/**/resources/**/*.xml` (Spring XML, MyBatis, etc.)
- `src/**/resources/db/**` and any Liquibase changelog (`*.xml`, `*.yaml`, `*.json`, `*.sql`)
- `src/**/resources/logback*.xml`, `log4j*.xml`, `log4j2.xml`
- Inline JPQL and native SQL strings inside `.java` files (often referencing class or column names)
- `src/test/resources/**`
- `README*`, `docs/**` (docs references are **informational**, not blocking — note them and move on)

## 2. Spring string indirection

These are framework features that resolve types and bean names via strings at runtime. A static analyser will miss them.

| Mechanism | What to search |
|-----------|----------------|
| `@Qualifier("name")` | Search for the bean name string |
| `@Component("name")`, `@Service("name")`, `@Bean(name = "name")` | Bean name strings |
| `@ConditionalOnProperty` / `@ConditionalOnBean` / `@ConditionalOnClass` | Property keys and class names |
| `@Value("${...}")`, SpEL `#{...}` | Method/property/bean names inside SpEL |
| `@PreAuthorize`, `@PostAuthorize`, `@Cacheable(key=...)`, `@CacheEvict` | SpEL referencing methods/types |
| `@Profile("name")` | Profile strings |
| `@EventListener`, `@TransactionalEventListener` | Event payload types (resolved by signature, not string — but check) |
| `@Scheduled(cron=..., fixedRate=...)` | Scheduled methods are entry points |
| `@KafkaListener`, `@RabbitListener`, `@JmsListener`, `@StreamListener` | Topic/queue/binding names and payload types |
| `@ConfigurationProperties(prefix="...")` | Property prefix; binding is reflective |
| `@RequestMapping`, `@GetMapping`, etc. | Handler methods are entry points (see [entry-points.md](entry-points.md)) |

## 3. Published API contract (OpenAPI / Swagger / springdoc)

The single biggest source of false positives in Spring Boot services: types and values that look unused in Java but are **published in the OpenAPI specification** for external API consumers. Removing them is a breaking change to the API contract, regardless of internal reference counts.

### What to search

| Annotation | Why it matters |
|------------|----------------|
| `@Schema(name=..., enumAsRef=true)` on an enum | **Every enum value is part of the published schema.** Client SDKs and consumers use these values. Unreferenced-in-Java does NOT mean removable. |
| `@Schema` on a class | Class is a documented DTO; its getters, setters, no-arg constructor are part of the contract |
| `@Schema(description=...)` on a field | Field is documented; even unused-in-this-repo, it ships in the spec |
| `@Operation`, `@ApiResponse`, `@ApiResponses` on a controller method | Handler is documented; the response/request type referenced is part of the contract |
| `@Parameter`, `@RequestBody` annotations referencing types | Those types are part of the contract |
| `@Tag` on a controller | Controller is grouped in the public docs |

### Concrete checks

```bash
# Is the candidate annotated with @Schema (any form)?
rg -n "@Schema" --type java <candidate-file>

# Is the candidate referenced from any @Schema / @ApiResponse / @RequestBody / @Parameter?
rg -nF "<SimpleName>" --type java | rg -E "@(Schema|ApiResponse|RequestBody|Parameter|Content|ArraySchema)"

# Is the candidate's enum value name referenced in any @Schema(allowableValues=...)?
rg -nF '"<EnumValueName>"' --type java | rg "allowableValues"
```

For enums specifically: if the enclosing enum has `@Schema(enumAsRef = true)`, **every constant is live by definition** — do not classify individual constants as Tier 1. Reclassify all of them as false positives with the `@Schema` annotation as evidence.

### Generated OpenAPI specs

Some projects commit the generated OpenAPI spec to the repo (often at `build/openapi/openapi.json`, `src/main/resources/openapi.yaml`, or a published `openapi.yaml`/`openapi.json` artifact). When present, **search the spec for the candidate's simple name** — any hit makes the candidate part of the published contract regardless of Java-side reference counts.

```bash
rg -nF "<SimpleName>" $(fd -e yaml -e yml -e json --search-path src/main/resources --search-path build/openapi 2>/dev/null) 2>/dev/null
```

### When the schema dictates "live, but reconsider"

Some `@Schema` annotations document types that *should* be deprecated. If the enum value or DTO field is in the spec but the team has decided to remove it from the public API:

1. The audit still classifies it as a false positive (it is live via the contract).
2. The team's path forward is a contract change (deprecate in the spec, then a major version bump), not a deletion driven by static analysis.
3. The audit can record this as a footnote ("API contract candidate — separate decision") but never auto-delete.

## 4. Serialisation surfaces and Spring Data repositories

### Spring Data repository methods (special case)

Methods declared on interfaces extending `JpaRepository`, `CrudRepository`, `PagingAndSortingRepository`, or `Repository` are **NOT classified by the presence of a Java implementation** — Spring Data materialises them at runtime from the method name (derived queries), an `@Query` annotation, or a JPA `@NamedQuery`. The signal "no impl found" is normal, not evidence of dead code.

The correct signal for a Spring Data interface method:

| Check | If… |
|-------|-----|
| Does any production code inject the repository and call this method? | Yes → live |
| Does the repository have other live methods? | Yes, but only the candidate method is uncalled → method is dead even though the repository is live |
| Is the candidate referenced from an `@Query("...")` or a `@NamedQuery` on a sibling class? | Yes → live |

A repository can be partially dead — the interface stays, individual methods get deleted. Treat each method as its own candidate. The deletion fanout is normally one file (the interface), but if the project has explicit test stubs implementing the interface (e.g. `JpaAddressRepositoryAdapterStub`) the override also goes in the same commit.

### Serialisation surfaces

If the class is on a serialisation boundary, its getters, setters, and no-arg constructor are **live even if unreferenced**.

- **Jackson DTOs.** Is the class used in any controller signature, `RestTemplate`/`WebClient` call, or message payload? Search:
  ```bash
  rg -n "ResponseEntity<.*BarDto" src/
  rg -n "(restTemplate|webClient)\.[a-zA-Z]+\([^)]*BarDto" src/
  rg -nF "BarDto" src/main/java | grep -E "(@RequestBody|@ResponseBody|Mono<|Flux<|List<|consumes|produces)"
  ```
- **JPA entities.** Hibernate uses reflection for every field — never delete fields of an `@Entity` based on static analysis alone. Cross-check the schema (Liquibase changelog or migration) before flagging any column-backed field.
- **MapStruct mappers.** A field used by a `@Mapper` interface may not appear in compiled-against bytecode. Search `*Mapper.java` for the field/method name.
- **JAXB / XML mappers.** `@XmlElement`, `@XmlRootElement` make fields reflectively reachable.

## 5. Direct reflection

```bash
rg -n "Class\.forName" src/
rg -n "getMethod\(|getDeclaredMethod\(" src/
rg -n "getField\(|getDeclaredField\(" src/
rg -n "MethodHandles\." src/
rg -n "ServiceLoader" src/
```

Also check:

- `src/main/resources/META-INF/services/` — files there list reflectively-loaded implementations
- AOP pointcut expressions: `@Around("execution(* com.example..*Service.*(..))")` — pointcuts match by **pattern**, so a class can be reflectively wrapped without any direct reference

## 6. Framework discovery

The candidate may implement or extend a type that Spring or a library discovers automatically. Check the supertypes of the candidate against this list:

- `org.springframework.core.convert.converter.Converter`
- `org.springframework.boot.actuate.health.HealthIndicator`
- `jakarta.servlet.Filter`, `org.springframework.web.filter.OncePerRequestFilter`
- `org.springframework.web.servlet.config.annotation.WebMvcConfigurer`
- `org.springframework.boot.CommandLineRunner`, `ApplicationRunner`
- `org.springframework.context.ApplicationListener`
- `liquibase.change.custom.CustomTaskChange`, `CustomSqlChange`
- `org.flywaydb.core.api.callback.Callback`
- `org.springframework.security.web.SecurityFilterChain` bean definitions
- Any `@Configuration` class registering `@Bean` methods that return the candidate's type

## 7. Build and infrastructure references

Static analysers do not scan build scripts. Check:

```bash
rg -nF "BarService" build.gradle build.gradle.kts settings.gradle*
rg -nF "com.example.foo.BarService" Dockerfile* docker-compose*.yml
rg -nF "BarService" .github/ .gitlab-ci.yml Jenkinsfile* 2>/dev/null
rg -nF "BarApplication" --glob '!**/target/**' --glob '!**/build/**'  # main class refs
```

A class referenced as a main class in `build.gradle` or a Dockerfile entrypoint is live.

## 8. Recording the evidence

For each candidate, record in the report which checks were run and their outcome:

```markdown
- `com.example.foo.BarService#processOrder()` — Tier 1
  - Plain string search: 0 hits outside the declaration
  - Spring indirection: no `@Qualifier`/SpEL/`@ConditionalOnProperty` hits
  - API contract: no `@Schema`/`@Operation`/`@ApiResponse` references; not in any generated OpenAPI spec
  - Serialisation: not a DTO, not an entity
  - Direct reflection: no `getMethod`/`Class.forName` hits
  - Framework discovery: does not extend a discovered supertype
  - Build/infra: no references in Gradle, Docker, CI
  - Verdict: no usage found via static analysis and the full reflection checklist
```

Skipping a check is fine when it is obviously inapplicable (e.g. skipping serialisation checks for a `private static` utility method), but say so explicitly in the evidence so a reviewer can challenge the call.
