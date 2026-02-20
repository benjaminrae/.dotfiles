---
name: hexagonal-module-scaffold
description: "Use when creating a new module in a hexagonal architecture project. Scaffolds the directory structure with domain, application, and infrastructure layers following DDD and CQRS patterns."
---

# Hexagonal Module Scaffold

## Overview

Scaffold a new module following hexagonal architecture (ports and adapters) with CQRS. The module structure enforces clean separation: domain core has no external dependencies, application layer orchestrates use cases, infrastructure adapts to external systems.

## Process

### Step 1: Gather module information

Ask the user:
1. What is the module name? (e.g., `notifications`, `billing`)
2. What is the core domain concept? (e.g., "notification", "invoice")
3. Does it need CQRS? (commands and queries, or just one?)
4. What external systems does it interact with? (database, message queue, external API)

### Step 2: Scaffold the directory structure

Create the directory tree following the template in `directory-template.md`.

### Step 3: Generate core files

For each layer, generate the appropriate interfaces and base classes:

**Domain layer:**
- Entity/Aggregate root with basic properties
- Repository interface (port) -- domain defines the contract
- Domain event(s) if the module publishes events

**Application layer:**
- Command handler(s) implementing `ICommandHandler`
- Query handler(s) implementing `IQueryHandler`
- Commands and queries as simple data classes

**Infrastructure layer:**
- Repository implementation (adapter) -- implements the domain interface
- Module registration file

### Step 4: Verify architecture boundaries

Remind the user to:
- Run architecture tests if available (`pnpm test:architecture`)
- Verify the domain layer has zero imports from infrastructure or framework
- Verify cross-module communication uses events, not direct imports

## Key Principles

- **Domain defines interfaces, infrastructure implements them** (Dependency Inversion)
- **Modules communicate only through events/messages** (no cross-module imports)
- **Shared concepts go in a shared kernel** (`src/shared/`)
- **Each module is self-contained** with its own domain, application, and infrastructure

See `directory-template.md` for the complete directory structure reference.
