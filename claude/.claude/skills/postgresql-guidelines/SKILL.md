---
name: postgresql-guidelines
description: "Use when writing or reviewing PostgreSQL code — schema design, migrations, queries, naming conventions. Enforces team PostgreSQL conventions and flags anti-patterns."
---

# PostgreSQL Guidelines

## Overview

This skill enforces team PostgreSQL conventions when writing or reviewing database code. It covers schema design, naming, query patterns, SQL style, and common anti-patterns. See `conventions-reference.md` for the full reference with examples.

<HARD-GATE>
NEVER use `ON DELETE CASCADE`. Handle deletions explicitly in application code where consequences are visible, testable, and auditable.
</HARD-GATE>

## Writing Mode

Use this checklist when implementing database changes (schemas, migrations, queries).

### Naming

- **Tables**: singular entity names, lowercase with underscores (`user_account`, `purchase_order`)
- **Columns**: camelCase (`createdAt`, `firstName`). PostgreSQL stores these as lowercase automatically
- **Primary keys**: `{tablename}Id` UUID (e.g. `userId UUID PRIMARY KEY DEFAULT gen_random_uuid()`)
- **Foreign keys**: match the target PK name (e.g. `userId` references `user.userId`). Use descriptive names for multiple FKs to the same table (`createdByUserId`, `approvedByUserId`)
- **Cross/join tables**: `{table1}_{table2}` (e.g. `user_role`, `order_product`)
- **Constraints and indexes**: follow `{prefix}_{table}_{field}` pattern:
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

- **NEVER** use `ON DELETE CASCADE` -- handle deletions explicitly in application code

### UPSERT

- **Avoid UPSERT in application code** except during data migrations
- Review trigger implications: `BEFORE INSERT` triggers fire even when the row takes the `ON CONFLICT DO UPDATE` path, and side-effects are not rolled back

### Timezone

- **Always store and transmit timestamps in UTC**
- Use `TIMESTAMPTZ` for all timestamp columns
- Convert to local time only at the presentation layer

### Partitioning

- **Range**: time-series or date-based data with known boundaries
- **List**: columns with a known, finite set of values (e.g. region codes)
- **Hash**: evenly distributing data when access patterns are unpredictable

## Review Mode

Use this checklist when reviewing PostgreSQL code. Report each violation with: **file path**, **line number**, **rule violated**, and **the fix**.

### Naming Violations

- Flag tables not using singular lowercase with underscores -- provide the correct name
- Flag columns not using camelCase -- provide the correct name
- Flag PKs not following `{tablename}Id` pattern -- provide the correct name
- Flag FKs not matching the target PK name -- provide the correct name
- Flag constraints/indexes not following `{prefix}_{table}_{field}` pattern -- provide the correct name

### Query Anti-Patterns

- Flag `COUNT(*)` used for existence checks -- use `EXISTS (SELECT 1 ...)`
- Flag `COUNT(*) > 1` for duplicate detection -- use `EXISTS` with a self-join
- Flag nested subqueries -- rewrite as CTEs or JOINs
- Flag loops, cursors, or row-by-row processing -- rewrite as set-based operations
- Flag `SELECT *` -- list only required columns
- Flag `IN` with correlated subqueries -- use `EXISTS`

### Missing Indexes

- Flag queries filtering or joining on unindexed columns where access patterns are apparent
- Suggest the appropriate index type (B-tree, GIN, GiST, BRIN) based on the data and query pattern

### Schema Issues

- Flag PostgreSQL ENUM types -- replace with reference table using short PK
- Flag missing primary keys
- Flag missing NOT NULL constraints where nullability is not justified
- Flag denormalization without documented justification

### CASCADE Rules

- **Any `ON DELETE CASCADE` is a violation** -- replace with explicit deletion in application code

### UPSERT Usage

- Flag UPSERT in application code unless it is part of a migration
- Note trigger implications if UPSERT is present

### Style Violations

- Flag lowercase SQL keywords -- rewrite in ALL CAPS
- Flag trailing commas -- rewrite with leading commas
- Flag missing semicolons at statement end
- Flag missing carriage returns between clauses
- Flag misaligned columns

## Anti-Patterns Quick Reference

| Anti-Pattern | Use Instead |
|--------------|-------------|
| `COUNT(*)` for existence | `EXISTS (SELECT 1 ...)` |
| `COUNT(*) > 1` for duplicates | `EXISTS` with self-join |
| Subqueries | CTEs or JOINs |
| Loops / cursors in SQL | Set-based operations |
| PostgreSQL `ENUM` type | Reference table with short PK |
| `ON DELETE CASCADE` | Explicit deletion in application code |
| `UPSERT` for non-migrations | Explicit `INSERT` or `UPDATE` |
| `SELECT *` | List only required columns |
| `IN` with correlated subquery | `EXISTS` |
| Trailing commas | Leading commas |
| Lowercase SQL keywords | ALL CAPS keywords |
| Missing semicolons | Always terminate with `;` |
| `TIMESTAMP` without timezone | `TIMESTAMPTZ` (always UTC) |