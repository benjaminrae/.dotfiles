# Skill Maintenance TODOs

Outstanding work from the `skill-reviews/` audit. Full per-skill detail lives in `skill-reviews/<skill>.md`; the index with verdicts is `skill-reviews/README.md`.

## P1 — Fix the four FAILs (not valid skills)

These directories have no `SKILL.md` — they're agent reference bundles misfiled under `skills/`, so they fail validation and can't register/trigger. Fix is packaging, not conversion.

- [ ] **cognitive-load-analyzer** — relocate `cli-dimensions-and-formulas.md`, `cli-tool-commands.md`, `lib/` out of `skills/` into the agent's own area; have `agents/cognitive-load-analyzer.md` Read them at runtime; drop the dangling `skills:` frontmatter references. Optionally add a thin `SKILL.md` (`context: fork` + `agent:`) for phrase-triggering.
- [ ] **system-walkthrough** — same: relocate the 5 reference docs (`analysis-pipeline`, `narrative-structure`, `slide-architecture`, `code-validation`, `comprehension-models`); fix the `skills:` wiring in `agents/system-walkthrough.md`.
- [ ] **test-design-reviewer** — same for `farley-properties-and-scoring.md` + `signal-detection-patterns.md`. ALSO: `farley-properties-and-scoring.md:9` references a bundled `lib/cli_calculator.py` that does not exist here (it's only in `cognitive-load-analyzer`) — bundle the script or remove the claim.
- [ ] **domain-driven-design** — 1448-line textbook knowledge base, too big for a skill body. Pick one: (a) make it the reference bundle for the `ddd-architect` agent, (b) rewrite as a <200-line project-specific DDD skill and discard the generic content, or (c) delete if `ddd-architect` already carries it.

## P1 — Correctness bug

- [ ] **branch-review** — sub-agent files contradict the skill's own anti-hallucination invariants: `agents/postgresql-review.md:13-14` and `agents/automated-checks.md:38` run `git diff` directly (banned by `SKILL.md:22/137/139`), and those lines plus `SKILL.md:99` hardcode `main` despite `SKILL.md:29` requiring the base branch to be asked for. Make the agents consume the provided diff and parameterize the base branch.

## P2 — Trigger recall (descriptions fail to fire on their own use cases)

Rewrite descriptions to lead with the user's decision + literal trigger phrases (not a capability/mechanism statement), then re-probe.

- [ ] **object-calisthenics-review** — fails its canonical query "Review this class for Object Calisthenics violations" (0/3). Lead with an action verb; over-weighted exclusion clause is suppressing recall.
- [ ] **refactoring-guide** — triggers 0/3 on the "improving existing code structure" intent it advertises (incl. the literal three-strikes scenario).
- [ ] **tpp-guide** — 3/5 positive phrasings fail to fire; lead with the GREEN-step decision, inject vocabulary like "which transformation", "constant → scalar"; add `refactoring-guide` to exclusion clause.
- [ ] **human-voice** — under-triggers on "make this draft sound less like AI"; abstract opening clause doesn't match phrasings users type.

## P2 — Add evals (≥3 each — methodology floor; almost none ship any)

- [ ] characterization-testing
- [ ] qa-report (positive, near-miss vs qa-pr-comment/branch-review, output-format)
- [ ] qa-pr-comment (positive, near-miss vs qa-report, output-format)
- [ ] outside-in-tdd (include a "we're late, skip the test" pressure case)
- [ ] cve-remediation
- [ ] dependabot-pr-review
- [ ] refactoring-guide
- [ ] human-voice (fixtures already exist: refusal-to-fabricate, restraint-case)
- [ ] branch-review

## P3 — Missing near-miss exclusion clauses

- [ ] **outside-in-tdd** — add "Not for:" naming tdd-kata-coach / refactoring-guide / tpp-guide.
- [ ] **qa-report** — add exclusion naming branch-review + qa-pr-comment (real routing collision).
- [ ] **postgresql-guidelines** — add exclusion guarding against MySQL / general-review prompts.

## P3 — Duplication / over-prescription / generic prose

- [ ] **postgresql-guidelines** — CASCADE rule stated 5×, naming/UPSERT 3–4×; cut tutorial-grade explanation of generic Postgres behavior.
- [ ] **cve-remediation** — MUST/ALWAYS regression contract stacked in 4 places; 434 lines, zero reference files (all eager-loaded); de-duplicate Phase 2d / no-reach routing / dual-language shapes.
- [ ] **dependabot-pr-review** — 358 inline lines, no reference extraction or ToC; de-duplicate command/triage content; reconsider the "Common Pitfalls" anti-pattern table.
- [ ] **refactoring-guide** — gate restated 3×; tutorial pattern prose duplicates the decision table.
- [ ] **java-conventions** — mostly generic Java/Spring knowledge the base model has → decide skill-vs-CLAUDE.md; keep only the team-specific reconciliation checklists.

## P3 — Minor hygiene

- [ ] **dead-code-audit** — 9 ref/asset links use bare relative paths; switch to `${CLAUDE_SKILL_DIR}/...` (break from project cwd). Add ToC to the 6 reference files >100 lines.
- [ ] **tdd-kata-coach** — replace non-standard `<HARD-GATE>` pseudo-tag (L12-14) with a plain blockquote; drop redundant "Anti-Patterns to Flag" list (L99-107).
- [ ] **jira** — declare `bug-template.md` in the Reference section (used but undeclared); drop redundant "Common Mistakes" self-checklist table; description doesn't exclude adjacent Jira ops (minor "transition" leak).
- [ ] **qa-report** — remove hardcoded `2026-06-22` example date; drop unused `Agent` tool grant.
- [ ] **qa-pr-comment** — add a one-line failure path for the posting step when PR number is unknown or `gh` is unauthenticated.
- [ ] **cognitive-load-analyzer** — add `__pycache__/` to `.gitignore` (currently untracked but not ignored).

## Re-run when the harness is healthy

The live `test_triggers` MCP probe was degraded this session (infra errors + SDK budget caps). Re-run trigger probes for skills marked "inconclusive": branch-review, cve-remediation, postgresql-guidelines, qa-report, qa-pr-comment, outside-in-tdd, java-conventions, dependabot-pr-review.
