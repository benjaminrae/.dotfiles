# PostgreSQL Conventions Reference

## Schema Design

- Design schemas in **Boyce-Codd Normal Form (BCNF)** as a baseline.
- Normalize to eliminate redundancy and update anomalies.
- Denormalize deliberately and document the reason when performance demands it.
- Every table must have a primary key.

## Naming Conventions

### General Rules

- Names must clearly represent their content and intention.
- Never use spaces in identifiers.
- Never use quotation marks around identifiers.
- Never use PostgreSQL reserved words as identifiers.
- PostgreSQL folds all unquoted identifiers to lowercase. camelCase for columns and key fields is a **source-readability convention only** — never rely on case to distinguish two identifiers, and never quote to preserve case.
- Multi-token object names (constraints, indexes) use lowercase snake_case so the stored, folded name stays readable.

### Database Names

- Always lowercase.
- Example: `inventory`, `user_management`

### Table Names

- Use **singular entity names** (the table represents the entity, not the collection).
- **PostgreSQL**: lowercase with underscores (`user_account`, `purchase_order`).
- **Application/ORM**: PascalCase (`UserAccount`, `PurchaseOrder`).
- Cross/join tables: `{table1}_{table2}` (e.g., `user_role`, `order_product`).

### Column Names

- Use **camelCase** in source (`createdAt`, `firstName`); PostgreSQL stores these folded to lowercase (`createdat`, `firstname`). The camelCase is for source readability only.
- **Application/ORM**: camelCase mapping is natural since the source names already match.
- Use short, singular names that describe the value they hold.

### Primary Key Fields

- Pattern: `{tablename}Id` (e.g. `userId`, `orderId`). PostgreSQL stores this as lowercase (`userid`).
- Use **UUID** as the data type when no natural key exists.
- Example: `userId UUID PRIMARY KEY DEFAULT gen_random_uuid()`

### Foreign Key Fields

- Use the **same name as the primary key** in the target table (e.g. `userId` references `user.userId`).
- When a table has multiple foreign keys to the same target table, choose distinct descriptive names.
- Example: `createdByUserId` and `approvedByUserId` both referencing `user.userId`.

## Constraint & Index Naming

Constraint and index names are lowercase snake_case throughout. A camelCase field like `userId` becomes the `user_id` segment so the name reads correctly after PostgreSQL folds it.

| Type | Pattern | Example |
|------|---------|---------|
| Primary Key | `pk_{tablename}_{field1}[_{field2}...]` | `pk_user_username` |
| Foreign Key | `fk_{sourcetable}_{sourcefield}` | `fk_order_user_id` |
| Unique | `uq_{tablename}_{field1}[_{field2}...]` | `uq_object_name` |
| Default Index (B-tree) | `idx_{tablename}_{field1}[_{field2}...]` | `idx_permission_object_id` |
| GIN Index | `gin_{tablename}_{field1}[_{field2}...]` | `gin_document_tags` |
| GiST Index | `gist_{tablename}_{field1}[_{field2}...]` | `gist_location_coordinates` |
| BRIN Index | `brin_{tablename}_{field1}[_{field2}...]` | `brin_events_timestamp` |

## Functions, Procedures & Triggers

| Type | Prefix | Example |
|------|--------|---------|
| Procedure | `p_` | `p_archiveExpiredSessions` |
| Function | `f_` | `f_calculateOrderTotal` |
| Trigger | `t_` | `t_updateModifiedAt` |

- All names use **camelCase** after the prefix.
- Parameters follow the same field naming conventions as columns.

## Query Anti-Patterns

### Never COUNT(*) when EXISTS suffices

```sql
-- Bad: scans and counts every matching row
SELECT COUNT(*)
FROM   order_item
WHERE  orderId = '...'
HAVING COUNT(*) > 0;

-- Good: stops at first match
SELECT EXISTS (
    SELECT 1
    FROM   order_item
    WHERE  orderId = '...'
);
```

### Never COUNT(*) > 1 for duplicate detection

```sql
-- Bad: counts all duplicates across the entire table
SELECT email
     , COUNT(*)
FROM   user_account
GROUP BY email
HAVING COUNT(*) > 1;

-- Good: stops as soon as a single duplicate is found
SELECT email
FROM   user_account ua1
WHERE  EXISTS (
    SELECT 1
    FROM   user_account ua2
    WHERE  ua2.email = ua1.email
      AND  ua2.userId <> ua1.userId
);
```

### Prefer CTEs over subqueries

```sql
-- Bad: nested subqueries are hard to read and debug
SELECT *
FROM   (
    SELECT orderId
         , total
    FROM   purchase_order
    WHERE  total > (
        SELECT AVG(total) FROM purchase_order
    )
) expensive_orders;

-- Good: CTEs read top-to-bottom
WITH average_total AS (
    SELECT AVG(total) AS avgTotal
    FROM   purchase_order
)
, expensive_orders AS (
    SELECT orderId
         , total
    FROM   purchase_order
    WHERE  total > (SELECT avgTotal FROM average_total)
)
SELECT *
FROM   expensive_orders;
```

### Never use loops in queries

Use **set-based operations** instead of row-by-row processing. If you find yourself reaching for `FOR` / `LOOP` / cursors inside SQL, rewrite with JOINs, CTEs, or window functions.

### Preemptively create indexes

When query access patterns are known at design time, create indexes immediately. Do not wait for performance complaints.

## SQL Style

- Write **ALL keywords in UPPER CASE** (`SELECT`, `FROM`, `WHERE`, `JOIN`, `ON`, `INSERT`, `UPDATE`, `DELETE`).
- Align columns vertically for readability.
- Use **leading commas** so every data line starts with `, `.
- Always terminate statements with a **semicolon**.
- Use **parentheses** to make operator precedence explicit.
- Use **carriage returns** to separate clauses.

### Example

```sql
SELECT ua.userId
     , ua.firstName
     , ua.lastName
     , ua.email
     , COUNT(po.orderId) AS orderCount
FROM   user_account ua
LEFT JOIN purchase_order po
       ON po.userId = ua.userId
WHERE  ua.createdAt >= '2024-01-01'
  AND  ua.status = 'active'
GROUP BY ua.userId
       , ua.firstName
       , ua.lastName
       , ua.email
HAVING COUNT(po.orderId) > 0
ORDER BY orderCount DESC;
```

## Data Types

### Avoid PostgreSQL ENUM

Do **not** use the `CREATE TYPE ... AS ENUM` construct. Disadvantages:

- Cannot rename existing values without recreating the type.
- Cannot remove values once added.
- No control over display or sort ordering.
- Harder to attach metadata (descriptions, active/inactive flags).
- Not standard SQL; causes problems with CDC (Change Data Capture) pipelines.

**Instead**, create a **reference table** with a **short primary key** (e.g., a 3-4 character code or a small integer). This gives full CRUD control, metadata columns, and foreign-key integrity.

```sql
CREATE TABLE order_status (
    code       VARCHAR(4) PRIMARY KEY  -- 'PEND', 'SHIP', 'DLVR'
  , label      VARCHAR(50) NOT NULL
  , sortOrder  SMALLINT NOT NULL
);
```

### UUID for Primary Keys

Use `UUID` for primary keys when no natural key exists. Generate with `gen_random_uuid()`.

## UPSERT Guidance

### Syntax

```sql
INSERT INTO user_preference (userId, preferenceKey, preferenceValue)
VALUES ('...', 'theme', 'dark')
ON CONFLICT (userId, preferenceKey)
DO UPDATE SET preferenceValue = EXCLUDED.preferenceValue;
```

### Trigger implications

A `BEFORE INSERT` trigger fires even when the row ends up taking the `ON CONFLICT DO UPDATE` path. The trigger side-effects are **not rolled back** when the operation converts to an update. This can cause unexpected audit records, sequence increments, or notification dispatches.

### Rule

**Team policy: avoid UPSERT in application code** except during data migrations where the trade-off is acceptable and well-understood — its trigger semantics (above) are surprising.

## Cascade Rules

**Team policy: NEVER use `ON DELETE CASCADE`.**

Cascading deletes silently destroy data across related tables. Instead, handle deletions explicitly in application logic where the consequences are visible, testable, and auditable.

## Timezone

**Always store and transmit timestamps in UTC.**

Use `TIMESTAMPTZ` (timestamp with time zone) for all timestamp columns. Convert to local time only at the presentation layer.

```sql
createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
```