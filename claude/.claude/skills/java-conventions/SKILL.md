---
name: java-conventions
description: Use when writing or reviewing Java/Spring Boot code — JPA mappings, Clean Architecture, migration consistency, and Spring patterns
---

# Java Conventions

## Overview

This skill enforces team conventions when writing or reviewing Java/Spring Boot code: JPA mappings, Clean Architecture boundaries, migration consistency, and REST/Spring patterns.

## When to Use

- Before creating or modifying JPA entities
- Before writing database migrations
- When designing or annotating REST controller methods (PUT/PATCH/OpenAPI)
- When writing DTOs or mapping between DTOs and entities
- When reviewing controller/service/repository boundaries or Java/Spring Boot code
- When unsure about Spring Boot annotation usage

## Clean Architecture Boundaries

- Controllers -> Services -> Repositories (never skip layers)
- DTOs at controller boundary, entities inside domain
- No JPA annotations in DTOs, no HTTP annotations in services

## JPA Modification Checklist

Before modifying any entity:
1. Check all repositories that query this entity
2. Check all services that use those repositories
3. Check all DTOs that map to/from this entity
4. Check all tests that reference this entity or its fields
5. Update ALL of the above when changing entity fields

If any of these are missed, reconcile them before proceeding — do not leave repositories, services, DTOs, or tests out of sync with the entity.

## Migration Consistency

After writing any migration:
1. Verify every column change is reflected in the JPA entity
2. Verify FK relationships match @ManyToOne/@OneToMany annotations
3. Run `./gradlew compileJava` (or the project's build tool) to catch annotation mismatches
4. Run full test suite to catch integration test failures

If a check fails or a column is missing from the entity, reconcile the entity and migration so both agree before proceeding — do not leave them divergent.

## HTTP Method Semantics

- Verify PUT methods require all fields (full resource replacement) and PATCH methods accept partial bodies (only changed fields)
- Ensure OpenAPI/Swagger annotations match actual controller method annotations