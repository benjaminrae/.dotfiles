---
name: postgresql-guidelines
description: "Use when writing or reviewing PostgreSQL code — schema design, migrations, queries, naming conventions, slow queries, cascade deletes, enum migrations, or naming inconsistencies in database objects."
---

# PostgreSQL Guidelines

## Overview

This skill enforces team PostgreSQL conventions when writing or reviewing database code. It covers schema design, naming, query patterns, SQL style, and common anti-patterns. See `conventions-reference.md` for the full reference with examples.

**Hard rule (team policy):** NEVER use `ON DELETE CASCADE`. Cascading deletes silently destroy data across related tables. Handle deletions explicitly in application code where consequences are visible, testable, and auditable.

## Writing Mode

Use this checklist when implementing database changes (schemas, migrations, queries).

### Naming

PostgreSQL folds every unquoted identifier to lowercase. camelCase is therefore a **source-readability convention only** for columns and key fields (`createdAt` is stored as `createdat`); never rely on case to distinguish two identifiers, and never wrap an identifier in double quotes to preserve case. Multi-token object names that must survive folding (constraints, indexes) use lowercase snake_case so the stored name stays readable.

- **Tables**: singular entity names, lowercase with underscores (`user_account`, `purchase_order`)
- **Columns**: camelCase in source (`createdAt`, `firstName`); stored lowercase by PostgreSQL
- **Primary keys**: `{tablename}Id` UUID (e.g. `userId UUID PRIMARY KEY DEFAULT gen_random_uuid()`)
- **Foreign keys**: match the target PK name (e.g. `userId` references `user.userId`). Use descriptive names for multiple FKs to the same table (`createdByUserId`, `approvedByUserId`)
- **Cross/join tables**: `{table1}_{table2}` (e.g. `user_role`, `order_product`)
- **Constraints and indexes**: lowercase snake_case, `{prefix}_{table}_{field}` pattern. Multi-word field segments use underscores (e.g. `fk_order_user_id`, `idx_permission_object_id`):
  - PK: `pk_{table}_{field}`
  - FK: `fk_{table}_{field}`
  - Unique: `uq_{table}_{field}`
  - B-tree index: `idx_{table}_{field}`
  - GIN index: `gin_{table}_{field}`
  - GiST index: `gist_{table}_{field}`
  - BRIN index: `brin_{table}_{field}`
- **Functions/procedures/triggers**: prefix with `f_`, `p_`, `t_` followed by camelCase (`f_calculateOrderTotal`)

### ORM Mapping

- **Tables**: PascalCase in application code (`UserAccount`, `PurchaseOrder`)
- **Columns**: camelCase in application code (natural mapping since column names are already camelCase)

### Schema Design

- Target **Boyce-Codd Normal Form (BCNF)** as baseline
- Denormalize deliberately and document the reason when performance demands it
- Use **reference tables** with a short PK (3-4 char code or small integer) instead of PostgreSQL ENUM types
- Use **UUID** for primary keys when no natural key exists
- Every table must have a primary key

### Queries

- Use **EXISTS** instead of `COUNT(*)` for existence checks
- Use **CTEs** over subqueries for readability
- Use **set-based operations** instead of loops, cursors, or row-by-row processing
- Create **indexes preemptively** when query access patterns are known at design time
- Prefer **EXISTS** over `IN` for correlated subqueries

### SQL Style

- Write **ALL keywords in UPPER CASE** (`SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`, `INSERT`, `UPDATE`, `DELETE`)
- Align columns vertically for readability
- Use **leading commas** so every data line starts with `, `
- Always terminate statements with a **semicolon**
- Use **parentheses** to make operator precedence explicit
- Use **carriage returns** to separate clauses

### Constraints

- **NEVER** use `ON DELETE CASCADE` — handle deletions explicitly in application code (team policy; see hard rule above)

### UPSERT

- **Team policy: avoid UPSERT in application code** except during data migrations — its trigger semantics are surprising
- Review trigger implications: `BEFORE INSERT` triggers fire even when the row takes the `ON CONFLICT DO UPDATE` path, and side-effects are not rolled back

### Timezone

- **Always store and transmit timestamps in UTC**
- Use `TIMESTAMPTZ` for all timestamp columns
- Convert to local time only at the presentation layer

## Review Mode

Use this checklist when reviewing PostgreSQL code. Report each violation with: **file path**, **line number**, **rule violated**, and **the fix**.

### Naming Violations

- Flag tables not using singular lowercase with underscores — provide the correct name
- Flag columns not using camelCase in source — provide the correct name
- Flag PKs not following `{tablename}Id` pattern — provide the correct name
- Flag FKs not matching the target PK name — provide the correct name
- Flag constraint/index names that are not lowercase snake_case or do not follow `{prefix}_{table}_{field}` (e.g. uppercase embedded in the name, which Postgres silently folds) — provide the correct lowercase name

### Query Anti-Patterns

- Flag `COUNT(*)` used for existence checks — use `EXISTS (SELECT 1 ...)`
- Flag `COUNT(*) > 1` for duplicate detection — use `EXISTS` with a self-join
- Flag nested subqueries — rewrite as CTEs or JOINs
- Flag loops, cursors, or row-by-row processing — rewrite as set-based operations
- Flag `SELECT *` — list only required columns
- Flag `IN` with correlated subqueries — use `EXISTS`

### Missing Indexes

- Flag queries filtering or joining on unindexed columns where access patterns are apparent
- Suggest the appropriate index type (B-tree, GIN, GiST, BRIN) based on the data and query pattern

### Schema Issues

- Flag PostgreSQL ENUM types — replace with reference table using short PK
- Flag missing primary keys
- Flag missing NOT NULL constraints where nullability is not justified
- Flag denormalization without documented justification

### CASCADE Rules

- **Team policy: any `ON DELETE CASCADE` is a violation** — replace with explicit deletion in application code

### UPSERT Usage

- Flag UPSERT in application code unless it is part of a migration
- Note trigger implications if UPSERT is present

### Style Violations

- Flag lowercase SQL keywords — rewrite in ALL CAPS
- Flag trailing commas — rewrite with leading commas
- Flag missing semicolons at statement end
- Flag missing carriage returns between clauses
- Flag misaligned columns

## Anti-Patterns Quick Reference

| Anti-Pattern | Use Instead |
|--------------|-------------|
| `COUNT(*)` for existence | `EXISTS (SELECT 1 ...)` — stops at first match |
| `COUNT(*) > 1` for duplicates | `EXISTS` with self-join |
| Subqueries for complex logic | CTEs or JOINs — read top-to-bottom, easier to debug |
| Loops / cursors in SQL | Set-based operations |
| PostgreSQL `ENUM` type | Reference table with short PK — full CRUD, metadata, CDC-safe |
| `ON DELETE CASCADE` | Explicit deletion in application code |
| `UPSERT` for non-migrations | Explicit `INSERT` or `UPDATE` (UPSERT fires `BEFORE INSERT` triggers that are not rolled back on the conflict path) |
| `SELECT *` | List only required columns |
| `IN` with correlated subquery | `EXISTS` |
| Trailing commas | Leading commas — easier to comment out individual fields |
| Lowercase SQL keywords | ALL CAPS keywords |
| Missing semicolons | Always terminate with `;` |
| Uppercase in constraint/index names | Lowercase snake_case (Postgres folds the uppercase silently) |
| Waiting for slow queries to add indexes | Create indexes preemptively when query patterns are known |
| `TIMESTAMP` without timezone | `TIMESTAMPTZ` (always UTC) |