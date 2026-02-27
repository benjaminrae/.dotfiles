# Java / Spring Boot Conventions

## Database & Migrations

- When modifying database migrations or DDL, ALWAYS verify that corresponding JPA entities, repositories, and integration tests are updated to match
- Never drop a column or change a schema without checking all Java code that references it
- Migration changes and JPA entity changes MUST be in the same commit

## JPA

- Verify annotation correctness: @ManyToOne vs @OneToOne, cascade types, fetch strategies
- When renaming or removing entity fields, search for all usages in repositories, services, DTOs, and test fixtures before making changes

## Spring Boot Patterns

- Follow Clean Architecture: controllers never import repositories directly
- DTOs at the boundary, entities inside the domain
- PUT for full replacement, PATCH for partial updates — ensure OpenAPI docs match actual annotations

## Testing

- Test classes in `src/test/java` mirroring `src/main/java` package structure
- Run the full test suite after cross-cutting changes (migrations, entity modifications, shared DTOs)
- E2E tests verify the actual HTTP API, not just unit behaviour

## Build

- Use `./gradlew test` (or `make test`) to verify — never skip the test suite
- `./gradlew compileJava` as a quick sanity check after entity/annotation changes