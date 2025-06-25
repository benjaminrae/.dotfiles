#!/bin/bash

move_with_backup() {
  local src="$1"
  local backup="${src}.old"

  if [ -f "$src" ] && [ ! -f "$backup" ]; then
    mv "$src" "$backup"
  fi
}

move_with_backup ~/.zshrc

stow -v --target=$HOME zsh tmux nvim