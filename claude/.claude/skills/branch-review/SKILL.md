Branch Review
Perform a comprehensive multi-agent code review and architecture review of all changes in the current branch compared to main. Output the results to /reviews/<branch-name>.md.

Overview
This skill launches multiple specialised review agents in parallel and then compiles a single review report. The review covers:

Clean Architecture compliance — dependency direction, no infrastructure leakage into application/domain
Test quality — deterministic, extensive, all happy and unhappy paths, correct response codes and bodies, no leaked internals
Test coverage — must be above 90%
Mutation testing — mutation score must be above 90% for changed classes
Static analysis (Sonar) — no issues
Formatting — no Spotless violations
CLAUDE.md standards — TDD, test doubles, naming, refactoring rules, TypeScript/Java conventions
Steps
1. Identify the branch and changed files
   BRANCH=$(git rev-parse --abbrev-ref HEAD)
   echo "Branch: $BRANCH"
   git diff --name-only main...HEAD
   Use the branch name (sanitised for filesystem) as the review filename.

2. Run automated checks in parallel
   Run these commands concurrently and capture their output:

2a. Run tests and generate coverage report
./gradlew :core:test :core:jacocoTestReport
After the tests pass, read the JaCoCo XML report at core/build/reports/jacoco/test/jacocoTestReport.xml and extract overall line/branch coverage percentages. Flag if coverage is below 90%.

2b. Run Spotless formatting check
./gradlew spotlessCheck
Report any formatting violations found.

2c. Run Sonar analysis (local)
./gradlew sonar
If Sonar is not available locally (requires token/server), skip this step and note it in the report. Alternatively, check for common Sonar-detectable issues manually: unused imports, empty catch blocks, code duplication, cognitive complexity.

2d. Run mutation testing on changed classes
Run PIT mutation testing against only the classes changed on the branch:

make mutation-test-changed
This uses the Makefile target that:

Computes the list of changed production Java classes vs develop
Passes them to ./gradlew :core:pitest -PpitTargetClasses="<classes>"
Excludes Configuration and CoreApplication classes automatically
After the command completes, read the PIT XML report at core/build/reports/pitest/mutations.xml and the HTML summary at core/build/reports/pitest/index.html. Extract:

Overall mutation score (killed / total mutations)
Per-class mutation scores for changed files
List of surviving mutants (mutations that were NOT killed by tests)
Flag if the overall mutation score is below 90%.

If make mutation-test-changed fails (e.g. pitest plugin not configured on this branch), note it in the report and skip this step.

3. Launch parallel review agents
   Launch these agents concurrently using the Task tool:

Agent 1: Architecture Review (code-reviewer)
Prompt the agent to:

Read ALL changed files on the branch (production + test code)
Verify clean architecture layers: domain → application → adapters/infrastructure
Check dependency direction: domain must NOT depend on application, infrastructure, or adapters. Application must NOT depend on infrastructure or adapters
Check that domain and application layers contain NO infrastructure terminology (no HTTP status codes, no JPA annotations, no Spring annotations, no REST concepts, no JSON references)
Check that ports (interfaces) are defined in the application layer, implementations in infrastructure
Check for proper separation: controllers in adapters, use cases in application, entities/value objects in domain
Report any violations with file paths and line numbers
Agent 2: Test Quality Review (code-reviewer)
Prompt the agent to:

Read ALL test files that were changed or added on the branch
Check tests are deterministic (no random data, no time-dependent assertions, no ordering assumptions)
Check ALL happy paths are covered at acceptance level
Check ALL unhappy/error paths are covered (validation errors, not found, conflicts, etc.)
Check HTTP response codes are correct and semantically appropriate (201 for creation, 404 for not found, etc.)
Check response bodies are correct and do NOT expose internal implementation details (no stack traces, no internal IDs that shouldn't be public, no infrastructure-specific fields)
Check that test doubles follow CLAUDE.md guidelines (manual test doubles preferred over framework mocks)
Check tests follow behaviour-driven testing, not implementation-driven
Check test naming follows conventions
Report any missing test scenarios and any issues found
Agent 3: CLAUDE.md Standards Review (code-reviewer)
Prompt the agent to:

Read ALL changed files (production + test)
Read the CLAUDE.md file for the project standards
Check that code follows TDD principles (test files should exist for all new production code)
Check naming conventions (descriptive names, no comments needed to explain code)
Check method visibility (prefer lowest visibility: private > protected > public)
Check for proper use of interfaces for behaviour and types for data structures
Check no any type usage (if TypeScript)
Check code is self-documenting without comments
Check refactoring patterns are applied correctly (no premature abstraction, three strikes rule)
Check for over-engineering or unnecessary complexity
Report any violations with file paths and line numbers
4. Read the JaCoCo coverage report
   After tests complete, parse the JaCoCo XML report to extract:

Overall line coverage percentage
Overall branch coverage percentage
Per-class coverage for changed files
Flag any class with coverage below 90%
5. Read the PIT mutation testing report
   After mutation tests complete, parse the PIT XML report at core/build/reports/pitest/mutations.xml to extract:

Total number of mutations generated
Number of mutations killed (detected by tests)
Number of mutations that survived (NOT detected — these indicate weak tests)
Overall mutation score percentage (killed / total)
Per-class mutation scores for changed files
For each surviving mutant: the file, line number, mutator type, and description
Flag any class with mutation score below 90%. List all surviving mutants as they indicate specific gaps in test coverage that line/branch coverage alone cannot detect.

6. Compile the review report
   Write the report to /reviews/<branch-name>.md with this structure:

# Branch Review: <branch-name>

**Date:** <current date>
**Commits reviewed:** <number of commits>
**Files changed:** <number of files>

## Summary

<Overall assessment: PASS / PASS WITH WARNINGS / FAIL>
<Brief summary of findings>

## 1. Clean Architecture Compliance

<Findings from Architecture Review agent>
<Table of violations if any>

### Verdict: PASS / FAIL

## 2. Test Quality

<Findings from Test Quality Review agent>

### Coverage
- Line coverage: X%
- Branch coverage: X%
- Per-class coverage for changed files (table)

### Missing test scenarios
<List any missing scenarios>

### Response codes and bodies
<Assessment of response code correctness>

### Verdict: PASS / FAIL

## 3. Mutation Testing

- Mutation score: X% (Y killed / Z total)
- Threshold: 90%

### Per-class mutation scores
<Table of class | mutations | killed | survived | score>

### Surviving mutants
<Table of file | line | mutator | description for each surviving mutant>
<Brief analysis of what each surviving mutant means for test quality>

### Verdict: PASS / FAIL

## 4. Formatting

<Spotless check results>

### Verdict: PASS / FAIL

## 5. Static Analysis

<Sonar results or manual checks>

### Verdict: PASS / FAIL

## 6. CLAUDE.md Standards Compliance

<Findings from Standards Review agent>

### Verdict: PASS / FAIL

## Action Items

<Numbered list of all issues that need to be fixed, ordered by severity>
7. Present the results
   After writing the report file, print a summary to the user showing:

The overall verdict
The path to the full report
The number of action items (if any)