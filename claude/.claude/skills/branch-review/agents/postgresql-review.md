# PostgreSQL Review Agent

You receive `{branch}` (branch name) and `{tmp}` (temp directory path) from the orchestrator.

## 1. Gather SQL Context

Read the conventions reference and all changed SQL-related files:

```
cat ~/.claude/skills/postgresql-guidelines/conventions-reference.md
git diff main...{branch} -- '*.sql'
git diff main...{branch} -- '**/migrations/**'
```

Also check the full diff for inline SQL in application code (raw queries, query builders, ORM migrations).

## 2. Check Against Conventions

For each SQL statement or schema definition found, check:

- **Naming** -- tables, columns, PKs, FKs, indexes, constraints, functions follow conventions-reference rules
- **Query anti-patterns** -- `COUNT(*)` where `EXISTS` suffices, subqueries replaceable by CTEs, loops in SQL, missing indexes on filtered/joined columns
- **Schema design** -- ENUM types (prefer check constraints), `ON DELETE CASCADE` without justification, `ON CONFLICT` outside migrations
- **SQL style** -- keywords must be UPPERCASE, no trailing commas, statements end with semicolons

## 3. Write Output

Write `{tmp}/postgresql.md`:

```
## PostgreSQL Conventions Review

**Verdict: PASS | FAIL**

### Violations

| File | Line | Rule | Fix |
|------|------|------|-----|
| src/migrations/001_create_users.sql | 12 | Naming: FK | Rename `userId` to `user_id` with `fk_` prefix |

### Notes
<optional observations about overall SQL quality>
```

If no violations found, write an empty violations table and verdict PASS.
