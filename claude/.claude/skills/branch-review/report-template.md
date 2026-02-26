# Report Template

This template is read by the report compiler agent to structure the final branch review output.
Each section maps to a result file in `reviews/.tmp/<branch>/` produced by the parallel review agents and automated checks.
Sections for unselected optional analyses should show "Not selected for this review."

---

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

## 7. Code Smell Detection

<If not selected, state: "Not selected for this review.">
<If selected: findings from code-smell-detector agent>
<Link to code-smell-detector-report.md for full details>

### Verdict: PASS / FAIL / NOT SELECTED

## 8. Cognitive Load Analysis

<If not selected, state: "Not selected for this review.">
<If selected: Cognitive Load Index score and per-dimension breakdown>

### Verdict: PASS / FAIL / NOT SELECTED

## 9. Test Design Quality

<If not selected, state: "Not selected for this review.">
<If selected: Farley Index score and per-property breakdown>

### Verdict: PASS / FAIL / NOT SELECTED

## 10. System Walkthrough

<If not selected, state: "Not selected for this review.">
<If selected: link to generated walkthrough deck>

### Verdict: GENERATED / NOT SELECTED

## 11. PostgreSQL Conventions

<If not selected, state: "Not selected for this review.">
<If selected: naming violations, query anti-patterns, schema design issues, SQL style violations>
<Table of violations: file | line | rule | fix>

### Verdict: PASS / FAIL / NOT SELECTED

## Action Items

<Numbered list of all issues that need to be fixed, ordered by severity>