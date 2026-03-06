ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -f ${ZINIT_HOME}/zinit.zsh ]]; then
    print -P "%F{220}Installing zinit plugin manager…%f"
    command mkdir -p "$(dirname $ZINIT_HOME)"
    command git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Oh-My-Zsh libs needed for theme
zinit snippet OMZL::git.zsh
zinit snippet OMZL::theme-and-appearance.zsh
zinit snippet OMZL::prompt_info_functions.zsh

# Theme
zinit snippet OMZT::agnoster

# Oh-My-Zsh plugins
zinit snippet OMZP::git
zinit snippet OMZP::aws

# External plugins
zinit light zsh-users/zsh-autosuggestions
zinit light MichaelAquilina/zsh-you-should-use
zinit light fdellwing/zsh-bat
zinit light zsh-users/zsh-syntax-highlighting

# Aliases
alias vim="nvim"
alias air='~/go/bin/air'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PATH
export PATH=$PATH:~/.npm-global/bin