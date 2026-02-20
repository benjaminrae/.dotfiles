#!/bin/bash

move_with_backup() {
  local src="$1"
  local backup="${src}.old"

  if [ -f "$src" ] && [ ! -f "$backup" ]; then
    mv "$src" "$backup"
  fi
}

move_dir_with_backup() {
  local src="$1"
  local backup="${src}.old"

  if [ -d "$src" ] && [ ! -L "$src" ] && [ ! -d "$backup" ]; then
    mv "$src" "$backup"
  fi
}

move_with_backup ~/.zshrc
move_with_backup ~/.claude/CLAUDE.md
move_with_backup ~/.claude/settings.json
move_dir_with_backup ~/.claude/skills
move_dir_with_backup ~/.claude/agents

stow -v --target=$HOME zsh tmux nvim claude