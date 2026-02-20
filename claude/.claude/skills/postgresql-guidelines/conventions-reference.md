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
- Use camelCase for column names. PostgreSQL lowercases all unquoted identifiers automatically.

### Database Names

- Always lowercase.
- Example: `inventory`, `user_management`

### Table Names

- Use **singular entity names** (the table represents the entity, not the collection).
- **PostgreSQL**: lowercase with underscores (`user_account`, `purchase_order`).
- **Application/ORM**: PascalCase (`UserAccount`, `PurchaseOrder`).
- Cross/join tables: `{table1}_{table2}` (e.g., `user_role`, `order_product`).

### Column Names

- Use **camelCase** (`createdAt`, `firstName`). PostgreSQL stores these as lowercase (`createdat`, `firstname`).
- **Application/ORM**: camelCase mapping is natural since the names already match.
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

| Type | Pattern | Example |
|------|---------|---------|
| Primary Key | `pk_{tablename}_{field1}[_{field2}...]` | `pk_user_username` |
| Foreign Key | `fk_{sourcetable}_{sourcefield}` | `fk_order_userId` |
| Unique | `uq_{tablename}_{field1}[_{field2}...]` | `uq_object_name` |
| Default Index (B-tree) | `idx_{tablename}_{field1}[_{field2}...]` | `idx_permission_objectId` |
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

**Avoid UPSERT in application code** except during data migrations where the trade-off is acceptable and well-understood.

## Cascade Rules

**NEVER use `ON DELETE CASCADE`.**

Cascading deletes silently destroy data across related tables. Instead, handle deletions explicitly in application logic where the consequences are visible, testable, and auditable.

## Partitioning

- **Range partitioning**: for time-series or date-based data with known boundaries.
- **List partitioning**: for columns with a known, finite set of values (e.g., region codes).
- **Hash partitioning**: for evenly distributing data when access patterns are unpredictable.
- Monitor partition sizes and query plans regularly; adjust boundaries or strategy as data grows.

## Timezone

**Always store and transmit timestamps in UTC.**

Use `TIMESTAMPTZ` (timestamp with time zone) for all timestamp columns. Convert to local time only at the presentation layer.

```sql
createdAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

## Security

- Apply **least privilege**: grant only the permissions each role needs.
- Use **strong passwords** and rotate them on a schedule.
- Enforce **SSL/TLS** for all client connections.
- Enable **encryption at rest** for the data directory and backups.
- Maintain **audit logging** for DDL changes and privileged operations.
- Perform **regular backups** and test restore procedures.

## Performance Tuning

### Query Optimization

- Use `EXPLAIN ANALYZE` to understand query plans before and after changes.
- Avoid `SELECT *`; list only the columns you need.
- Ensure JOINs operate on indexed columns.
- Prefer `EXISTS` over `IN` for correlated subqueries.

### Configuration Parameters

- **`shared_buffers`**: start at 25% of available RAM; tune based on `pg_stat_bgwriter` hit ratios.
- **`work_mem`**: increase for complex sorts and hash joins; be cautious as it is per-operation.
- **`checkpoint_segments`** (or `max_wal_size` in modern PostgreSQL): increase to reduce checkpoint frequency for write-heavy workloads.

### Monitoring

- **`pg_stat_activity`**: identify long-running queries, idle-in-transaction connections, and lock contention.
- **`pg_stat_statements`**: find the most expensive queries by total time, calls, and rows returned.