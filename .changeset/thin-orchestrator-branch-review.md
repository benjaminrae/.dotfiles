---
"@benjaminrae/dotfiles": minor
---

Restructure branch-review skill to use thin orchestrator pattern, reducing orchestrator context from ~2K words to ~350 words. All review logic delegated to agent instruction files that subagents read independently. Report template extracted to standalone file. Background agents write findings to temp files instead of returning results to orchestrator context.