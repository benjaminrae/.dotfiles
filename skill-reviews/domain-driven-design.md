# Skill Review: domain-driven-design

**This is not a functioning skill.** The directory contains no `SKILL.md` — only a 1448-line knowledge-base document (`ddd-expert-knowledge-base.md`). Without an entry-point file and frontmatter the skill can never load or trigger, so the validator floor FAILS and every content dimension is moot. **Overall verdict: FAIL (blocking).**

## Validator output

`mcp__plugin_oberskills_skill-eval__validate_skill` was run against `/Users/benjamin.rae/cowork/dev/.dotfiles/claude/.claude/skills/domain-driven-design`:

```json
{
  "valid": false,
  "errors": [
    { "rule": "skill-md-missing", "message": "no SKILL.md in the skill directory", "file": "SKILL.md" }
  ],
  "warnings": [],
  "info": [],
  "stats": { "skill_md_lines": 0, "description_chars": 0, "reference_files": 0 }
}
```

**Result: FAIL.** One blocking ERROR: `skill-md-missing` — there is no `SKILL.md` in the directory. Location: the skill root itself.

Directory contents (confirmed via `find`, including hidden files):

```
./ddd-expert-knowledge-base.md   (53,910 bytes, 1448 lines)
```

For contrast, every sibling skill in the same tree has a `SKILL.md` (branch-review, characterization-testing, cve-remediation, dead-code-audit, dependabot-pr-review, human-voice, java-conventions, jira, object-calisthenics-review, outside-in-tdd, …). This skill is the sole exception.

Note: a `ddd-architect` subagent exists in the agent registry. The header comment on line 1 of the KB file (`<!-- Based on Andrea Laforgia's claude-code-agents -->`) plus the framing on line 4 (`It serves as the foundational knowledge base for a DDD expert agent.`) strongly suggest this file was authored as a **reference document for an agent**, not as a skill. It has been misplaced into `skills/` without the SKILL.md wrapper that the skills spec requires.

## Trigger probe

`test_triggers` was **not run and cannot be run**. The trigger harness wraps a candidate skill's listing surface — `name` + `description` + `when_to_use` — into a temporary plugin and probes whether Claude emits a `Skill` tool_use. With no `SKILL.md` there is no name, no description, and no `when_to_use`; there is nothing to register and nothing to probe. `description_chars: 0` in the validator stats confirms the empty listing surface.

Practical consequence: **this skill is invisible to the model.** It will never appear in the skills list and can never be invoked, regardless of how strong the underlying DDD content is. The 1448 lines of knowledge are dead weight on disk until a SKILL.md with a triggering description is authored.

## Dimension verdict

| Dimension | Status | Issue | Remediation |
|---|---|---|---|
| Validator floor | **FAIL** | `skill-md-missing` — no `SKILL.md`; `description_chars: 0`; `reference_files: 0`; zero evals | Create `SKILL.md` with valid frontmatter (`name: domain-driven-design`, third-person `description`); add ≥3 evals; re-validate |
| Triggers | **FAIL** | No description exists to trigger on — skill is unregisterable and unreachable | Author a third-person description leading with the key use case (reviewing/designing for DDD compliance) with near-miss exclusions |
| Structure | **FAIL** | No SKILL.md, so no point-of-decision content; the lone file is a 1448-line monolith referenced by nothing | Add SKILL.md as the entry point; demote the KB to a one-level reference with a TOC (it already has one) |
| Over-prescription | **N/A** | Cannot assess — no procedural skill body exists. The file is descriptive prose, not instructions to Claude | Re-assess once a SKILL.md procedure exists; watch for textbook tone (see Conciseness) |
| Conciseness | **WARN** | The KB is written *about* DDD as an educational textbook, not *to* Claude as actionable guidance; ~54 KB largely restates concepts the model already knows | If kept as a reference, prune to project-specific conventions / decision rules; drop generic textbook explanation |
| Workflow completeness | **FAIL** | No gates, no failure paths, no exit conditions — there is no workflow at all | Define what the skill makes Claude *do* (review a model? design aggregates?) with explicit steps and stop conditions |
| Banned constructs | **PASS** | No anti-rationalization tables, self-assessed-compliance checklists, or "Red Flags — STOP" blocks present in the file | None |
| Supply chain | **PASS** | No scripts, executables, or `scripts/` directory; pure markdown | None |
| Hygiene | **WARN** | Filename `ddd-expert-knowledge-base.md` ≠ skill name; line 1 leaks provenance comment; line 722 cites a "2009 February" MSDN article and other dated sources (acceptable as citations); no README/CHANGELOG present (good) | Rename reference to match convention; ensure citations are clearly historical references not stale instructions |

## Findings (ranked by severity)

### 1 — BLOCKING: No SKILL.md; the skill cannot exist
**Evidence:** `validate_skill` → `"rule":"skill-md-missing","message":"no SKILL.md in the skill directory"`. `find . -type f` returns exactly one file: `./ddd-expert-knowledge-base.md`. `stats.skill_md_lines: 0`.

This is the only finding that matters until it is fixed. A skill directory is defined by its `SKILL.md` entry point; without it the directory is not a skill, it is a stray document. It cannot be listed, triggered, validated past this error, or evaluated.

**Fix:** Create `/Users/benjamin.rae/cowork/dev/.dotfiles/claude/.claude/skills/domain-driven-design/SKILL.md` with YAML frontmatter:
- `name: domain-driven-design` (matches directory, ≤64 chars, lowercase + hyphens, no "claude"/"anthropic")
- `description:` third person, ≤1024 chars, no XML, leading with the concrete use case. Example shape: *"Use when designing or reviewing code for Domain-Driven Design — bounded contexts, aggregates, value objects, ubiquitous language, anemic-model smells. Not for general OO review (use object-calisthenics-review) or post-green refactoring (use refactoring-guide)."*
- A short body that tells Claude **what to do**, linking to the KB as a one-level reference (`See [ddd-expert-knowledge-base.md](./ddd-expert-knowledge-base.md)`).
- ≥3 evals.

### 2 — HIGH: The bundled content is a textbook, not skill instructions
**Evidence:** Line 4: *"It serves as the foundational knowledge base for a DDD expert agent."* Line 60: *"Domain-Driven Design (DDD) is a software development methodology that centers development on programming a domain model…"*. The entire file (lines 55–1397) is encyclopedic exposition of DDD concepts — Evans Classification, CQRS, Data Mesh, Xapo Bank case study — written in the third person *about* the domain.

Most of this is content Opus already knows (definitions of entities/value objects, Law of Demeter, what CQRS is). A skill should encode the *non-obvious, project-specific decision rules and conventions* the model would otherwise get wrong — not re-teach textbook DDD. As written, even if wrapped in a SKILL.md, the reference would burn tokens restating common knowledge.

**Fix:** When authoring the SKILL.md, keep the reference lean: project conventions, the specific review checklist you want applied, and the few genuinely load-bearing distinctions (e.g. transaction boundaries, aggregate access rules). Drop or heavily compress the generic survey material. Consider routing this through the existing `ddd-architect` agent rather than a skill if the intent is advisory rather than procedural.

### 3 — MEDIUM: This file appears to belong to the `ddd-architect` agent, not the skills tree
**Evidence:** Line 1: `<!-- Based on Andrea Laforgia's claude-code-agents: https://github.com/andlaf-ak/claude-code-agents -->`. Line 4 names it a knowledge base "for a DDD expert agent." A `ddd-architect` subagent is registered in the environment ("expert guidance on Domain-Driven Design principles… without writing implementation code").

The misplacement is likely the root cause of the missing SKILL.md: an agent reference doc was dropped into `skills/` by mistake.

**Fix:** Decide the intended surface. If it is agent-supporting reference material, move it next to the agent definition and delete this skill directory. If a skill is genuinely wanted, author the SKILL.md (Finding 1) and treat this file as its reference.

### 4 — LOW: Hygiene — filename and provenance comment
**Evidence:** The reference file is named `ddd-expert-knowledge-base.md` (does not match the skill/dir name). Line 1 leaks an authoring-provenance HTML comment into the shipped artifact. Sources such as line 722 (`/2009/february/…`) are dated.

**Fix:** Rename the reference to a convention-aligned name once the SKILL.md exists; remove or relocate the provenance comment to a CONTRIBUTING note (not the shipped reference); keep dated URLs only as clearly-marked citations, never as live guidance.

## Recommendations (prioritized)

1. **Decide skill vs. agent first.** The file self-identifies as agent knowledge and a `ddd-architect` agent exists. If advisory, move the file to the agent and delete this directory — that resolves everything below at once.
2. **If a skill is wanted, create `SKILL.md`** with valid frontmatter and a triggering third-person description (Finding 1). This is the single blocking fix; nothing else can be assessed until it lands.
3. **Re-run `validate_skill`** to clear `skill-md-missing`, then **run `test_triggers`** (should-trigger: "review this aggregate design", "is my domain model anemic", "where should this bounded context boundary go"; near-miss: "review this branch", "refactor after green", "general code review").
4. **Slim the reference** to project-specific DDD conventions and a concrete review checklist; cut generic textbook exposition Claude already knows (Finding 2).
5. **Add ≥3 evals** and clean up hygiene (rename reference, drop provenance comment) before shipping.
