#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/benjaminrae/.dotfiles/main/git"
DEST="$HOME/.gitconfig"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

info() {
    printf "${GREEN}[INFO]${RESET} %s\n" "$1"
}

warn() {
    printf "${YELLOW}[WARN]${RESET} %s\n" "$1"
}

error() {
    printf "${RED}[ERROR]${RESET} %s\n" "$1" >&2
}

# Backup existing .gitconfig
if [ -f "$DEST" ]; then
    backup="${DEST}.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backing up existing file: $DEST -> $backup"
    cp "$DEST" "$backup"
fi

# Download
url="${REPO_URL}/.gitconfig"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$DEST"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$DEST"
else
    error "Neither curl nor wget is available. Cannot download files."
    exit 1
fi

printf "\n${GREEN}Installation complete.${RESET} Installed .gitconfig to %s\n" "$DEST"