(( $+commands[fzf] )) && eval "$(fzf --zsh)"

# Keep zoxide's `z` command; the custom cd wrapper in functions provides the
# directory-exists fallback and delegates unmatched paths to zoxide.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[fasd] )) && eval "$(fasd --init auto)"
(( $+commands[starship] )) && eval "$(starship init zsh)"

[[ -r "$HOME/.zsh/codex_completion.zsh" ]] && source "$HOME/.zsh/codex_completion.zsh"
