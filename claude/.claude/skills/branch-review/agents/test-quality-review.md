# Test Quality Review Agent

You receive `{branch}` (branch name) and `{tmp}` (temp directory path) from the orchestrator.

## 1. Gather Test Files

Get changed/added test files and read their full diffs plus the production files they cover:

```
git diff --name-only main...{branch} -- '*.spec.ts' '*.test.ts' '*.spec.js' '*.test.js'
```

## 2. Review Each Test File

Check:

- **Determinism** -- no `Math.random()`, `Date.now()` in assertions, ordering assumptions, or flaky timeouts
- **Happy path coverage** -- all success scenarios for each public behaviour are tested
- **Unhappy path coverage** -- validation errors, not-found, conflicts, edge cases, and boundaries
- **Response correctness** -- status codes and bodies are asserted and semantically appropriate
- **Test doubles** -- manual doubles preferred over framework mocks; no implementation leakage
- **Behaviour-driven** -- tests describe what the system does, not how; no assertions on internals
- **Naming** -- test names describe behaviour in plain language

## 3. Write Output

**You MUST use the Bash tool** (not Write) to save `{tmp}/test-quality.md`. Use `cat <<'EOF' > file`.

```
## Test Quality Review

**Verdict: PASS | FAIL**

### Missing Scenarios
<untested happy/unhappy paths with the file they should cover>

### Issues

| File:Line | Category | Description |
|-----------|----------|-------------|

### Notes
<optional observations>
```

If no issues found, write empty tables and verdict PASS.