# Automated Checks Agent

You receive `{branch}` (branch name) and `{tmp}` (temp directory path) from the orchestrator.

## 1. Discover Repo Tooling

Read whichever of these files exist in the repo root:

| File | Look for |
|------|----------|
| `CLAUDE.md` | Project-specific test, lint, build, coverage commands |
| `package.json` | `scripts`: test, lint, format, coverage, typecheck |
| `Makefile` | Targets: test, lint, format, coverage, mutation |
| `build.gradle(.kts)` | Tasks: test, jacocoTestReport, spotlessCheck, pitest |
| `pom.xml` | Goals: test, verify, spotbugs, checkstyle |
| `Cargo.toml` | cargo test, cargo clippy, cargo fmt |
| `pyproject.toml` / `setup.cfg` | pytest, ruff, black, mypy |
| `README.md` / `CONTRIBUTING.md` | Documented development commands |

Build a tooling map for: **Tests**, **Coverage**, **Linting**, **Formatting**, **Static Analysis**, **Mutation Testing** -- each with the discovered command and whether it is available.

**If a tool is not available, mark it as NOT AVAILABLE. Do not fail the review.**

## 2. Run Checks

Run each available tool. Redirect verbose output to log files to keep conversation context clean:

`{tmp}/tests.log`, `{tmp}/coverage.log`, `{tmp}/lint.log`, `{tmp}/format.log`, `{tmp}/static-analysis.log`, `{tmp}/mutation.log`

Keep only the exit code and a one-line summary in the conversation. Run independent checks concurrently where possible.

## 3. Parse Reports

**Coverage:** Read the generated report (LCOV, Istanbul JSON, JaCoCo XML, coverage.py XML, etc.) and extract:
- Overall line and branch coverage percentages
- Per-file coverage for changed files (`git diff --name-only main...{branch}`)
- Flag any file below 90%

**Mutation testing (if available):** Read the mutation report and extract:
- Total mutations, killed, survived, overall score (killed/total)
- Per-file scores for changed files
- Each surviving mutant: file, line, mutator type, description
- Flag any file below 90%

## 4. Write Output

Write `{tmp}/automated-checks.md`:

```
## Automated Checks

| Category         | Status                                |
|------------------|---------------------------------------|
| Tests            | PASS / FAIL / NOT AVAILABLE           |
| Coverage         | X% line, Y% branch / NOT AVAILABLE   |
| Linting          | PASS / FAIL / NOT AVAILABLE           |
| Formatting       | PASS / FAIL / NOT AVAILABLE           |
| Static Analysis  | PASS / FAIL / NOT AVAILABLE           |
| Mutation Testing | X% (Y/Z killed) / NOT AVAILABLE      |

### Coverage Details
<per-file table for changed files, flag any below 90%>

### Surviving Mutants (if available)
<table: file | line | mutator | description>
```
