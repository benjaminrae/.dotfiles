# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a GNU Stow-based dotfiles repository. Each top-level directory is a stow package that gets symlinked into `$HOME`.

## Installation

```bash
# Full install: backs up existing files and symlinks all packages to $HOME
./install.sh

# Claude config only (standalone, no stow required):
./install-claude.sh

# Or via curl:
curl -fsSL https://raw.githubusercontent.com/benjaminrae/.dotfiles/main/install-claude.sh | bash
```

## Versioning

Uses changesets for versioning. After making changes to the claude config:

```bash
npx changeset        # Create a changeset describing the change
npx changeset version  # Bump version and update CHANGELOG
```

## Architecture

### Stow Packages

- **zsh/** → `~/.zshrc` - Oh-my-zsh with agnoster theme, nvm, git plugin. Aliases `vim` to `nvim`.
- **tmux/** → `~/.tmux.conf` - Dracula-style theme, prefix rebound to `C-a`, uses tpm.
- **nvim/** → `~/.config/nvim/` - Git submodule pointing to `benjaminrae/kickstart.nvim`.
- **claude/** → `~/.claude/` - Claude Code config: CLAUDE.md, skills, agents, settings.

### Claude Config Structure

```
claude/.claude/
├── CLAUDE.md          # Distributable dev guidelines (TDD, TypeScript principles)
├── settings.json      # Portable permissions and plugin config
├── skills/
│   ├── jira/          # Jira issue creation (Task, Bug, Story, Subtask)
│   └── branch-review/ # Multi-agent branch review with tooling discovery
└── agents/
    ├── code-reviewer.md
    ├── typescript-expert.md
    └── debugger-specialist.md
```

### Git Submodules

nvim and tmux are git submodules. After cloning:

```bash
git submodule update --init --recursive
```

Changes to nvim or tmux config should be committed in their respective upstream repos.