# Optional starter Zsh config — Obsidian / Emerald
# Merge with your existing ~/.zshrc if you already have custom setup.

setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias g='git'
alias gs='git status --short --branch'
alias gl='git log --oneline --graph --decorate -12'
alias gd='git diff'
alias dc='docker compose'

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
