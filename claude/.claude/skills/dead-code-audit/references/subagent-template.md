# Subagent Verification Template

The verification step scales poorly when done sequentially — a 30-candidate audit means 30 × 8 searches. Dispatch one subagent per candidate (or per file cluster) and run them in parallel.

## When to use parallel verification

- More than ~6 candidates to verify
- Candidates span multiple modules / archetypes (no shared context to amortise)
- A first run that already produced `candidates.json`

For fewer candidates or when context is shared (all candidates in one file), verify inline — the parallel-dispatch overhead isn't worth it.

## Prompt template — single-candidate verifier

Use the `Explore` subagent type. Substitute every `{...}` placeholder before dispatch: the candidate's metadata, `{REPO_ROOT}`, and `{SKILL_DIR}` (the absolute path of this skill's directory — resolve it at orchestration time; do not hardcode it).

```
You are verifying a single dead-code candidate against the reflection checklist
described in {SKILL_DIR}/references/verify-candidate.md.

Candidate:
  id:      {CANDIDATE_ID}
  type:    {class|method|field}
  file:    {REPO_RELATIVE_PATH}
  package: {PACKAGE}
  module:  {MODULE}

Repo root: {REPO_ROOT}

Run the 8-step mechanical procedure in verify-candidate.md. For each step,
record the search command you ran and a short summary of hits (count and
location, not full content). DO NOT skip steps; even "0 hits" must be
recorded — skipping is a defect.

Output ONLY the following structured markdown block (no preamble, no
chit-chat):

- `{CANDIDATE_ID}` — proposed tier: {Tier 1 | Tier 2 | Tier 3 | False positive}
  - Step 1 (plain refs): {N hits in main, N hits in test, locations of non-declaration hits}
  - Step 2 (API contract): {@Schema/@Operation evidence or "none"}
  - Step 3 (Spring indirection): {evidence or "none"}
  - Step 4 (Spring Data): {applicable? evidence or "n/a"}
  - Step 5 (serialisation): {DTO/entity/Mapper evidence or "none"}
  - Step 6 (direct reflection): {evidence or "none"}
  - Step 7 (framework discovery): {extends/implements evidence or "none"}
  - Step 8 (build/infra): {evidence or "none"}
  - Verdict: {one-sentence justification of the tier}

Keep the whole block under 25 lines. The user will paste it directly into the
dead-code-report.md.
```

## Dispatch loop

When you have a list of candidates to verify, dispatch them in batches sized to the runtime's concurrency cap (~8 by default in Claude Code). Inline pseudo-code:

```
for batch in candidates.main (one batch per concurrency cap):
  dispatch Explore subagent per candidate using the template above
  collect their evidence blocks
  append to dead-code-report.md under the appropriate tier
```

If Claude is the orchestrator, use the Agent tool with `subagent_type: "Explore"` and `run_in_background: true` for the batch, then collect results when the notifications arrive.

## When NOT to use this template

- The candidate is a JPA entity field — Hibernate reflects on every field; static analysis cannot decide this. Flag for human review instead of dispatching.
- The candidate is in a module that publishes a library consumed by other repos (e.g. `event-publisher` in sites-db) — cross-repo callers are invisible to in-repo `rg`. Default to Tier 3 (canary) instead of running the procedure.
- The candidate is annotated `@SuppressWarnings("unused")` already — the team has already opted out; record as a false positive and move on.

## Output normalisation

When evidence blocks come back, group them in the report by:

1. Verdict (Tier 1, Tier 2, Tier 3, false positive)
2. Within each verdict, by package or feature cluster
3. Within each cluster, by file

This is the order the report renders in, and it matches the cluster-per-commit grouping the deletion branch will use.
