#!/bin/bash

move_with_backup() {
  local src="$1"
  local backup="${src}.old"

  if [ -e "$src" ] && [ ! -e "$backup" ]; then
    if [ -L "$src" ]; then
      cp -L "$src" "$backup"
      rm "$src"
    else
      mv "$src" "$backup"
    fi
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
move_with_backup ~/.zprofile
move_with_backup ~/.zshenv
move_with_backup ~/.claude/CLAUDE.md
move_with_backup ~/.claude/settings.json
move_dir_with_backup ~/.claude/skills
move_dir_with_backup ~/.claude/agents
move_dir_with_backup ~/.claude/hooks
move_dir_with_backup ~/.claude/templates

move_with_backup ~/.gitconfig

stow -v --target=$HOME zsh tmux nvim claude git