# Entry Points and Allowlist

Some code is reachable but not visible to static analysis because the framework, the runtime, or another service calls it. Treat these as **roots**: they are never deletion candidates regardless of in-repo reference counts. If static analysis flags one of these, the candidate is automatically reclassified live (record it in the false-positives section).

## Built-in Roots

### Application bootstrap

- `public static void main(String[] args)`
- Classes annotated `@SpringBootApplication`, `@EnableAutoConfiguration`, `@SpringBootConfiguration`
- Classes referenced as `mainClass` in `build.gradle` / `application.mainClass` / Dockerfile `ENTRYPOINT`/`CMD`

### Web entry points

- `@RestController`, `@Controller` classes
- Handler methods inside them annotated with `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@PatchMapping`, `@DeleteMapping`, `@RequestPart`, `@MessageMapping`
- `@ExceptionHandler`, `@ControllerAdvice`, `@RestControllerAdvice` and their methods
- `@InitBinder`, `@ModelAttribute` methods on controllers
- `WebMvcConfigurer`, `WebFluxConfigurer`, `HandlerInterceptor`, `Filter`, `OncePerRequestFilter` implementations

### Asynchronous and scheduled

- `@Scheduled` methods (cron, fixed-rate, fixed-delay)
- `@EventListener`, `@TransactionalEventListener`
- `@KafkaListener`, `@RabbitListener`, `@JmsListener`, `@StreamListener`, `@SqsListener` and the methods they annotate
- `@Async` methods (callers may be reflective via `AsyncAnnotationAdvisor`)

### Spring auto-discovered beans

- `@Component`, `@Service`, `@Repository`, `@Configuration` types (these may be live without a direct reference — verified by checking for `@Qualifier`/SpEL/property-key references in the reflection checklist)
- `@Bean` methods inside `@Configuration` classes
- `org.springframework.core.convert.converter.Converter` implementations
- `org.springframework.boot.actuate.health.HealthIndicator` implementations
- `org.springframework.boot.CommandLineRunner`, `ApplicationRunner` implementations
- `org.springframework.context.ApplicationListener` implementations
- `org.springframework.security.web.SecurityFilterChain` bean methods
- `org.springframework.boot.autoconfigure.AutoConfiguration` classes registered in `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` (or legacy `spring.factories`)

### Data layer

- `@Entity`, `@MappedSuperclass`, `@Embeddable`, `@Converter` (JPA)
- Repository interfaces extending `JpaRepository`, `CrudRepository`, `PagingAndSortingRepository`, `Repository`
- Liquibase `CustomTaskChange`, `CustomSqlChange`, custom validators
- Flyway `Callback` implementations

### Test infrastructure (out of scope entirely)

Anything in `src/test/java`, `src/integrationTest/java`, `src/testFixtures/java` whose purpose is to support tests is **out of scope** for this skill. This includes:

- JUnit `@TestConfiguration`, `@SpringBootTest` configurations
- Test fixtures, builders, factories (e.g. `*Builder`, `*Fixture`, `*Factory` in test source sets)
- Test utility classes
- `@TestComponent`, `@MockBean`-supporting classes

The skill must not flag these as Tier 1/Tier 2. They are tools used by humans writing future tests, even if no current test references them.

## Per-Repo Allowlist

Each repo may have a `dead-code-allowlist.txt` at the repo root. The skill reads this file (if present) before classification and treats every matched item as a root.

**Format.** One entry per line. Lines starting with `#` are comments. Blank lines are ignored.

Each entry is a Java fully-qualified name pattern using `*` as a wildcard:

```
# Public API exposed to other services in the platform
com.example.publicapi.*

# Reflectively-loaded plugins (loaded by ServiceLoader)
com.example.plugin.SomePlugin

# Methods listed by full signature
com.example.foo.LegacyService#someMethod(java.lang.String)

# A whole package and everything beneath it
com.example.experimental.**
```

Pattern semantics:

- `*` matches any sequence of characters except `.`
- `**` matches any sequence of characters including `.` (use for whole sub-trees)
- `#` separates a type from a method, optionally followed by `(parameter,types)` for overload disambiguation

**First-run behaviour.** If the file is absent, the skill must:

1. Mention it once in the report header: "No `dead-code-allowlist.txt` found at the repo root. Consider adding one to encode team agreements about public/reflective entry points."
2. Proceed with the audit using only the built-in roots.

**Never invent allowlist entries.** The allowlist is a team agreement; the skill prompts the user to add an entry when a false positive is detected, but does not silently add entries on the user's behalf.

## Out-of-Scope Paths

Regardless of allowlist, never instrument or delete files matching:

- `**/build/**`, `**/target/**`, `**/out/**`, `**/.gradle/**`
- `**/generated/**`, `**/generated-sources/**`, `**/generated-test-sources/**`
- `**/src/**/jOOQ/**`, `**/src/**/jooq/**` (jOOQ generated)
- `**/openapi/**` if generated by an OpenAPI Generator plugin
- Anything under `src/**` whose package is declared in a Gradle `srcDir` flagged as generated
- Vendored third-party code under `src/main/java/vendor/` (project convention; check repo for similar patterns)

If unsure whether a directory is generated, check `build.gradle`/`build.gradle.kts` for `sourceSets { main { java { srcDirs(...) } } }` entries pointing at `build/generated/...`.
