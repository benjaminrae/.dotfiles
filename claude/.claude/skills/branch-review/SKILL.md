---
name: branch-review
description: Perform a comprehensive multi-agent code review of all changes in the current branch compared to main. Discovers repo tooling automatically and outputs results to reviews/<branch-name>.md.
---

## Overview

This skill launches multiple specialised review agents in parallel and then compiles a single review report. The review covers:

- Architecture compliance — check against any stated architecture, or apply general clean architecture principles
- Test quality — deterministic, extensive, all happy and unhappy paths, behaviour-driven
- Test coverage — must be above 90%
- Mutation testing — mutation score must be above 90% for changed files (if available)
- Static analysis / linting — no issues
- Formatting — no violations
- CLAUDE.md standards — TDD, test doubles, naming, refactoring rules, language conventions

## Steps

### Step 1: Identify branch and changed files

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Branch: $BRANCH"
git diff --name-only main...HEAD
```

Use the branch name (sanitised for filesystem — replace `/` with `-` and remove special characters) as the review filename: `reviews/<branch-name>.md`.

### Step 2: Discover repo tooling

Inspect the following files to build a tooling map. Read whichever exist in the repo root:

| File | What to look for |
|------|-----------------|
| `CLAUDE.md` | Project-specific test, lint, build, coverage commands |
| `package.json` | `scripts` section: `test`, `lint`, `format`, `coverage`, `typecheck` |
| `Makefile` | Targets for `test`, `lint`, `format`, `coverage`, `mutation` |
| `build.gradle` / `build.gradle.kts` | Tasks: `test`, `jacocoTestReport`, `spotlessCheck`, `sonar`, `pitest` |
| `pom.xml` | Maven goals: `test`, `verify`, `spotbugs`, `checkstyle` |
| `Cargo.toml` | `cargo test`, `cargo clippy`, `cargo fmt` |
| `pyproject.toml` / `setup.cfg` | `pytest`, `ruff`, `black`, `mypy` |
| `README.md` / `CONTRIBUTING.md` | Documented development commands |

Build a tooling map with these categories:

| Category | Discovered command | Available? |
|----------|--------------------|------------|
| Tests | e.g. `npm test`, `./gradlew test`, `cargo test` | Yes / No |
| Coverage | e.g. `npm run coverage`, `./gradlew jacocoTestReport` | Yes / No |
| Linting | e.g. `npm run lint`, `cargo clippy`, `ruff check .` | Yes / No |
| Formatting | e.g. `npm run format`, `cargo fmt --check`, `black --check .` | Yes / No |
| Static Analysis | e.g. `npx tsc --noEmit`, `mypy`, `spotbugs` | Yes / No |
| Mutation Testing | e.g. `npm run mutation`, `make mutation-test`, `./gradlew pitest` | Yes / No |

If a category has no discoverable tool, mark it as "Not available" and skip running it. Do not fail — note it in the report.

### Step 3: Run automated checks in parallel

Using the discovered tooling, run the following concurrently and capture all output:

**3a. Tests + coverage**
Run the discovered test command followed by the coverage command (if available). After they complete, read the generated coverage report (format depends on tooling: LCOV, Istanbul JSON, JaCoCo XML, coverage.py XML, etc.) and extract overall line/branch coverage percentages. Flag any value below 90%.

**3b. Formatting check**
Run the discovered formatting check command. Report any violations found. If not available, skip and note it.

**3c. Static analysis / linting**
Run the discovered linting and static analysis commands. Report any issues found. If not available, skip and note it.

**3d. Mutation testing**
Run the discovered mutation testing command (if available). If not available, skip this step entirely and mark the section as NOT AVAILABLE in the report. Do not fail the review because mutation testing is absent.

### Step 4: Launch parallel review agents

Launch these three agents concurrently using the Task tool:

**Agent 1: Architecture Review (code-reviewer)**

Prompt the agent to:
- Read ALL changed files on the branch (production + test code) using `git diff main...HEAD`
- Check against any architecture documented in `CLAUDE.md`, `README.md`, or `ARCHITECTURE.md` if present; otherwise apply general clean architecture principles (separation of concerns, dependency inversion, single responsibility)
- Check that domain/core logic contains no infrastructure or framework-specific dependencies
- Check that interfaces/ports are defined at the appropriate boundary layer
- Check for proper separation of concerns across layers
- Report any violations with file paths and line numbers

**Agent 2: Test Quality Review (code-reviewer)**

Prompt the agent to:
- Read ALL test files that were changed or added on the branch
- Check tests are deterministic (no random data, no time-dependent assertions, no ordering assumptions)
- Check ALL happy paths are covered
- Check ALL unhappy/error paths are covered (validation errors, not found, conflicts, etc.)
- Check response codes and bodies are correct and semantically appropriate (where applicable)
- Check that test doubles follow CLAUDE.md guidelines (manual test doubles preferred over framework mocks)
- Check tests follow behaviour-driven testing, not implementation-driven testing
- Check test naming follows conventions
- Report any missing test scenarios and any issues found

**Agent 3: CLAUDE.md Standards Review (code-reviewer)**

Prompt the agent to:
- Read ALL changed files (production + test)
- Read the project's `CLAUDE.md` for standards
- Check that code follows TDD principles (test files should exist for all new production code)
- Check naming conventions (descriptive names, self-documenting without comments)
- Check method/function visibility (prefer lowest necessary visibility)
- Check for proper use of interfaces for behaviour and types/structs for data
- Check there is no over-engineering or unnecessary complexity
- Check refactoring patterns are applied correctly (no premature abstraction, three strikes rule observed)
- Report any violations with file paths and line numbers

### Step 5: Parse coverage and mutation reports

After the automated checks complete:

**Coverage:** Extract from whichever report format the tooling produced:
- Overall line coverage percentage
- Overall branch coverage percentage (if available)
- Per-file coverage for changed files

Flag any file with coverage below 90%.

**Mutation testing (if available):** Extract from the mutation report:
- Total mutations generated
- Mutations killed (detected by tests)
- Mutations that survived (NOT detected — indicate weak tests)
- Overall mutation score (killed / total)
- Per-file mutation scores for changed files
- For each surviving mutant: the file, line number, mutator type, and description

Flag any file with mutation score below 90%. List all surviving mutants as they indicate specific gaps in test quality that line/branch coverage alone cannot detect.

### Step 6: Compile review report

Write the report to `reviews/<branch-name>.md` with this structure:

```markdown
# Branch Review: <branch-name>

**Date:** <current date>
**Commits reviewed:** <number of commits>
**Files changed:** <number of files>

## Summary

<Overall assessment: PASS / PASS WITH WARNINGS / FAIL>
<Brief summary of findings>

## 1. Architecture Compliance

<Findings from Architecture Review agent>
<Table of violations if any>

### Verdict: PASS / FAIL

## 2. Test Quality

<Findings from Test Quality Review agent>

### Coverage
- Line coverage: X%
- Branch coverage: X% (if available)
- Per-file coverage for changed files (table)

### Missing test scenarios
<List any missing scenarios>

### Verdict: PASS / FAIL

## 3. Mutation Testing

<If not available, state: "Mutation testing tooling not detected in this repository.">

- Mutation score: X% (Y killed / Z total)
- Threshold: 90%

### Per-file mutation scores
<Table of file | mutations | killed | survived | score>

### Surviving mutants
<Table of file | line | mutator | description for each surviving mutant>
<Brief analysis of what each surviving mutant means for test quality>

### Verdict: PASS / FAIL / NOT AVAILABLE

## 4. Formatting

<Formatting check results, or "Not available" if no tool discovered>

### Verdict: PASS / FAIL / NOT AVAILABLE

## 5. Static Analysis

<Linting and static analysis results, or "Not available" if no tool discovered>

### Verdict: PASS / FAIL / NOT AVAILABLE

## 6. CLAUDE.md Standards Compliance

<Findings from Standards Review agent>

### Verdict: PASS / FAIL

## Action Items

<Numbered list of all issues that need to be fixed, ordered by severity>
```

### Step 7: Present results

After writing the report file, print a summary to the user showing:

- The overall verdict (PASS / PASS WITH WARNINGS / FAIL)
- The path to the full report
- The number of action items (if any)