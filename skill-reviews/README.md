# Skill Reviews

Audits of every skill under `claude/.claude/skills/`, produced with the `skill-craft` REVIEW methodology (deterministic `validate_skill` floor → content dimensions → trigger probe). One file per skill.

## How to read these

Each report grades nine dimensions PASS / WARN / FAIL with quoted evidence: validator floor, triggers, structure, over-prescription, conciseness, workflow completeness, banned constructs, supply chain, hygiene.

> **Harness caveat:** the live `test_triggers` MCP probe was degraded this session — most runs returned infrastructure errors and a few hit the SDK budget cap. Trigger verdicts marked "inconclusive" rest on manual description analysis and should be re-run on a healthy harness. A handful of skills did get clean probe runs (noted below).

## Verdict summary

| Skill | Verdict | Headline issue |
|---|---|---|
| [characterization-testing](characterization-testing.md) | **PASS** | Clean; add ≥3 evals, minor token trims |
| [tdd-kata-coach](tdd-kata-coach.md) | **PASS** | Clean; cosmetic `<HARD-GATE>` pseudo-tag + a redundant list |
| [jira](jira.md) | **PASS (minor)** | MCP names correct; minor near-miss leak on "transition" + undeclared template |
| [cve-remediation](cve-remediation.md) | **PASS w/ changes** | Over-prescription (MUST stacked 4×), 434 lines all eager-loaded |
| [dead-code-audit](dead-code-audit.md) | **PASS (minor)** | Bare relative ref paths break from project root; add ToCs |
| [postgresql-guidelines](postgresql-guidelines.md) | **PASS w/ warnings** | Heavy duplication (CASCADE stated 5×); tutorial-grade prose |
| [qa-report](qa-report.md) | **PASS (minor)** | No "Not for" clause (collides w/ siblings); 0 evals; hardcoded date |
| [qa-pr-comment](qa-pr-comment.md) | **PASS (reservations)** | 0 evals; trigger probe inconclusive; add posting failure path |
| [outside-in-tdd](outside-in-tdd.md) | **WARN** | No near-miss exclusion clause; 0 evals |
| [branch-review](branch-review.md) | **WARN** | Self-contradiction: agents run `git diff` + hardcode `main` vs core invariants |
| [java-conventions](java-conventions.md) | **WARN** | Mostly generic Java/Spring knowledge → candidate for CLAUDE.md |
| [dependabot-pr-review](dependabot-pr-review.md) | **PASS w/ warnings** | 358 lines no refs/ToC; command duplication |
| [refactoring-guide](refactoring-guide.md) | **WARN** | Triggers 0/3 on "improve existing code structure" intent |
| [tpp-guide](tpp-guide.md) | **WARN** | Trigger recall: 3/5 positive phrasings failed to fire |
| [object-calisthenics-review](object-calisthenics-review.md) | **WARN** | Broken recall — fails to fire on its own canonical use case |
| [human-voice](human-voice.md) | **WARN** | Under-triggers on "sound less like AI"; 5 portability warnings; 0 evals |
| [cognitive-load-analyzer](cognitive-load-analyzer.md) | **FAIL (floor)** | No SKILL.md — it's an agent + reference docs misfiled under skills/ |
| [domain-driven-design](domain-driven-design.md) | **FAIL (floor)** | No SKILL.md — 1448-line knowledge base, belongs to ddd-architect agent |
| [system-walkthrough](system-walkthrough.md) | **FAIL (floor)** | No SKILL.md — agent + reference docs misfiled under skills/ |
| [test-design-reviewer](test-design-reviewer.md) | **FAIL (floor)** | No SKILL.md; references a `lib/cli_calculator.py` that isn't bundled |

## Cross-cutting findings

**1. Four "skills" are actually agents (FAIL at the floor).** `cognitive-load-analyzer`, `domain-driven-design`, `system-walkthrough`, and `test-design-reviewer` have no `SKILL.md` — they are agent definitions plus reference docs misfiled under `skills/`. They cannot register, trigger, or be evaluated. Fix is structural: move them next to their agents (the `ddd-architect`, `cognitive-load-analyzer`, etc. agents already exist) or wrap each with a real `SKILL.md` (third-person description + ≥3 evals). `test-design-reviewer` additionally claims a bundled `lib/cli_calculator.py` that only exists in `cognitive-load-analyzer` — a broken reproducibility guarantee.

**2. Almost no skill ships the ≥3 evals the methodology requires.** This is the single most common gap across the passing skills. Evals are what would have caught the trigger-recall failures below.

**3. Trigger recall is the dominant real defect.** Where clean probe runs were possible, several skills fail to fire on their own advertised use cases: `object-calisthenics-review` (canonical query, 0/3), `tpp-guide` (3/5 positives fail), `refactoring-guide` (0/3 on "improve existing code structure"), `human-voice` ("sound less like AI"). Common cause: descriptions that lead with a capability/mechanism statement instead of the user's actual decision and literal trigger phrases.

**4. Missing near-miss exclusion clauses.** `outside-in-tdd`, `qa-report`, `postgresql-guidelines`, and others lack a "Not for:" clause even though sibling skills point back at them — a routing-collision surface.

**5. `branch-review` has a genuine correctness bug, not just a trigger nit.** Sub-agent files run `git diff` directly and hardcode `main`, contradicting the skill's own core anti-hallucination invariants (agents must not run `git diff`; ask for the base branch). HIGH severity.

**6. Duplication / over-prescription / tutorial prose** recur in the larger reference skills (`postgresql-guidelines`, `cve-remediation`, `dependabot-pr-review`, `java-conventions`, `refactoring-guide`) — facts restated 3–5×, generic domain knowledge the base model already has, and stacked MUST/ALWAYS framing. These inflate per-session token cost and invite drift.

**7. Supply chain is clean everywhere.** Every bundled script inspected is pure stdlib, read-only, no network calls, no obfuscation. No supply-chain risk found.

## Suggested priority order

1. **Fix the four FAILs** — relocate the misfiled agents or add `SKILL.md` wrappers; bundle/remove `test-design-reviewer`'s missing script.
2. **Fix `branch-review`'s `git diff` / hardcoded-`main` contradiction** (correctness).
3. **Repair trigger recall** on `object-calisthenics-review`, `refactoring-guide`, `tpp-guide`, `human-voice` (description rewrites, then re-probe on a healthy harness).
4. **Add ≥3 evals** to every shipping skill, starting with those whose triggering is unproven.
5. **Trim duplication / generic prose**; decide skill-vs-CLAUDE.md for `java-conventions`.
