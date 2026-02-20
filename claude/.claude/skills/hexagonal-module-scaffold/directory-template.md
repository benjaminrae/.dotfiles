# Hexagonal Module Directory Template

## Standard Module Structure

```
src/{module-name}/
├── app/                          # Primary adapters (entry points)
│   ├── controllers/              # HTTP/GraphQL controllers
│   ├── consumers/                # Message queue consumers
│   └── commands/                 # CLI commands
│
├── application/                  # Use cases (orchestration)
│   ├── command/                  # Write operations
│   │   ├── {action}/
│   │   │   ├── {Action}Command.ts
│   │   │   └── {Action}CommandHandler.ts
│   │   └── index.ts
│   ├── query/                    # Read operations
│   │   ├── {query-name}/
│   │   │   ├── {QueryName}Query.ts
│   │   │   └── {QueryName}QueryHandler.ts
│   │   └── index.ts
│   └── service/                  # Application services (if needed)
│
├── domain/                       # Core business logic (NO external dependencies)
│   ├── model/                    # Entities, aggregates, value objects
│   │   ├── {EntityName}.ts
│   │   └── {ValueObjectName}.ts
│   ├── event/                    # Domain events
│   │   └── {EntityAction}Event.ts
│   ├── port/                     # Repository interfaces (contracts)
│   │   └── {EntityName}Repository.ts
│   └── service/                  # Domain services (if needed)
│
└── infrastructure/               # Secondary adapters (external systems)
    ├── persistence/              # Database implementations
    │   ├── entity/               # ORM entities
    │   ├── repository/           # Repository implementations
    │   └── migration/            # Database migrations
    ├── messaging/                # Message queue adapters
    │   ├── publisher/
    │   └── consumer/
    ├── external/                 # External API clients
    └── {module-name}.module.ts   # Module registration
```

## Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Commands | `{Verb}{Noun}Command` | `CreateAuditCommand` |
| Command Handlers | `{Verb}{Noun}CommandHandler` | `CreateAuditCommandHandler` |
| Queries | `Get{Noun}Query` or `Find{Noun}Query` | `GetAuditByIdQuery` |
| Query Handlers | `{QueryName}QueryHandler` | `GetAuditByIdQueryHandler` |
| Domain Events | `{Noun}{PastTenseVerb}Event` | `AuditCreatedEvent` |
| Repository Interfaces | `{EntityName}Repository` | `AuditRepository` |
| Repository Implementations | `{ORM}{EntityName}Repository` | `TypeOrmAuditRepository` |

## Dependency Rules

```
app/ -------> application/ -------> domain/
  |                                    ^
  +---> infrastructure/ ──────────────+
```

- `domain/` imports NOTHING from other layers
- `application/` imports only from `domain/`
- `infrastructure/` imports from `domain/` (to implement ports)
- `app/` can import from `application/` and `infrastructure/` (for wiring)
