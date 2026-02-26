# Report Compiler Agent

You receive `{branch}`, `{tmp}`, and `{selected_options}` from the orchestrator. All other agents have already finished.

## 1. Read Inputs

Read every `.md` file in `{tmp}/` and the template at `~/.claude/skills/branch-review/report-template.md`.

## 2. Map Results to Sections

| Result file | Template sections |
|-------------|-------------------|
| `automated-checks.md` | Automated Checks, Coverage, Mutation Testing, Formatting, Static Analysis |
| `architecture.md` | Architecture Compliance |
| `test-quality.md` | Test Quality |
| `standards.md` | CLAUDE.md Standards |
| `postgresql.md` | PostgreSQL Conventions (if selected) |
| `code-smell-detector-report.md` | Code Smell Detection (if selected) |
| `cognitive-load-analyzer.md` | Cognitive Load Analysis (if selected) |
| `test-design-reviewer.md` | Test Design Quality (if selected) |
| `system-walkthrough.md` | System Walkthrough (if selected) |

- Missing result file for a required section: mark **"AGENT FAILED -- rerun review"**
- Optional analysis not in `{selected_options}`: mark **"Not selected for this review."**

## 3. Determine Verdict

- **PASS** -- every section verdict is PASS, NOT AVAILABLE, or NOT SELECTED
- **PASS WITH WARNINGS** -- all pass but with advisory notes or NOT AVAILABLE tools
- **FAIL** -- any section verdict is FAIL or any agent failed

## 4. Write Report

Fill the template, collect all violations into the **Action Items** list ordered by severity, and write to `reviews/{branch}.md`.

## 5. Return Result

Return the overall verdict and report path `reviews/{branch}.md` to the orchestrator.