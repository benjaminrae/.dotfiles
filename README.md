# .dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/), including Claude Code configuration with custom skills and agents.

## Quick Start

### Full Install (all dotfiles)

Requires [GNU Stow](https://www.gnu.org/software/stow/).

```bash
git clone --recursive https://github.com/benjaminrae/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

This backs up existing files and symlinks all packages into `$HOME`.

### Claude Config Only

No dependencies required — downloads and installs to `~/.claude/`:

```bash
curl -fsSL https://raw.githubusercontent.com/benjaminrae/.dotfiles/main/install-claude.sh | bash
```

Options:
- `--claude-only` — install only CLAUDE.md
- `--skills-only` — install only skills
- `--agents-only` — install only agents

## What's Included

### Stow Packages

| Package | Target | Description |
|---------|--------|-------------|
| `zsh/` | `~/.zshrc` | Oh-my-zsh with agnoster theme, nvm, git plugin |
| `tmux/` | `~/.tmux.conf` | Dracula-style theme, prefix rebound to `C-a`, tpm plugins |
| `nvim/` | `~/.config/nvim/` | [kickstart.nvim](https://github.com/benjaminrae/kickstart.nvim) (git submodule) |
| `claude/` | `~/.claude/` | Claude Code config: dev guidelines, skills, agents |

### Claude Code Configuration

**CLAUDE.md** — Development guidelines enforcing TDD, TypeScript strict mode, behaviour-driven testing, and refactoring discipline.

**Skills:**

| Skill | Description |
|-------|-------------|
| `jira` | Create Jira issues (Task, Bug, Story, Subtask) with auto-detection, validation, and context-aware descriptions |
| `branch-review` | Multi-agent code review that discovers repo tooling automatically |

**Agents:**

| Agent | Description |
|-------|-------------|
| `code-reviewer` | Code review for quality, security, performance, and best practices |
| `typescript-expert` | Advanced TypeScript development: type system, build config, migration |
| `debugger-specialist` | Systematic debugging: root cause analysis, memory leaks, race conditions |

## Versioning

This repo uses [changesets](https://github.com/changesets/changesets) to track changes to the Claude configuration.

```bash
npx changeset          # Describe a change
npx changeset version  # Bump version and update CHANGELOG
```

## License

MIT