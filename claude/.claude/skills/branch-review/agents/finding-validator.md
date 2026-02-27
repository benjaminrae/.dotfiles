# Finding Validator Agent

You receive `{branch}`, `{tmp}` from the orchestrator. All review agents have already finished and their outputs are in `{tmp}/`.

## Purpose

Cross-check every finding from review agents against actual source code to filter hallucinated issues.

## 1. Read All Review Outputs

Read every `.md` file in `{tmp}/` except files produced by automated checks (automated-checks.md). Focus on files that contain code review findings:
- `architecture.md`
- `test-quality.md`
- `standards.md`
- `postgresql.md` (if present)

## 2. Extract Findings

For each review output, extract individual findings. A finding typically includes:
- A file path reference
- A line number or range (if provided)
- A description of the issue

## 3. Validate Each Finding

For each finding:

**a. Read the referenced file and line**
- Use the Read tool to open the actual file at the referenced location
- Read enough context (10 lines before and after) to understand the code

**b. Classify the finding**

| Classification | Criteria | Action |
|----------------|----------|--------|
| **VERIFIED** | The actual code confirms the claimed issue exists | Keep in report |
| **UNVERIFIABLE** | Cannot confirm or deny from code alone (architectural opinions, naming preferences, design concerns) | Keep with confidence note |
| **HALLUCINATED** | The actual code contradicts the claim (e.g., "missing null check" but null check exists, "wrong annotation" but annotation is correct) | Remove from report |

**c. Record evidence**
For VERIFIED: quote the relevant code line(s)
For HALLUCINATED: quote the code that disproves the claim

## 4. Write Output

Write `{tmp}/validated-findings.md` with this structure:

```
# Validated Findings

## Summary
- Total findings reviewed: N
- Verified: N
- Unverifiable: N
- Hallucinated: N

## Verified Findings

### [Source: architecture.md] Finding description
**File:** path/to/file.java:42
**Evidence:** `actual code line`
**Original finding:** quote from review agent

(repeat for each verified finding)

## Unverifiable Findings

### [Source: standards.md] Finding description
**Reason:** Cannot confirm from code alone — requires runtime/architectural context
**Original finding:** quote from review agent

(repeat for each unverifiable finding)

## Hallucinated Findings (Removed)

### [Source: test-quality.md] Finding description
**File:** path/to/file.java:15
**Disproof:** `actual code showing the claim is wrong`
**Original finding:** quote from review agent

(repeat for each hallucinated finding)
```

## 5. Return Result

Return the validation summary (counts) and the path `{tmp}/validated-findings.md` to the orchestrator.