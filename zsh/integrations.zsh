eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(fasd --init auto)"

# Powerlevel10K prompt.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

