# Completion files must be on fpath before Prezto initializes its completion
# module. Keep the per-user completion directory optional.
[[ -d "$HOME/.zsh/my-completions" ]] && fpath=("$HOME/.zsh/my-completions" $fpath)

# Keep the original command search order while preserving paths supplied by
# the environment. The unique attribute also prevents duplicates in PATH.
typeset -gU path
path=(
  /bin
  "$HOME/bin"
  "$HOME/bin/Digital"
  "$HOME/.local/bin"
  /usr/bin
  /usr/bin/core_perl
  /usr/bin/site_perl
  /usr/bin/vendor_perl
  /usr/lib/jvm/default/bin
  /usr/lib/rustup/bin
  /usr/local/bin
  /usr/local/sbin
  /var/lib/snapd/snap/bin
  /opt/kafka/bin
  $path
)

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# History
HISTSIZE=500000
HISTFILE=~/.zshistory
SAVEHIST=$HISTSIZE
HISTDUP=erase

#WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'

WORDCHARS="_"

setopt EXTENDED_GLOB
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Turn off spelling corrections
unsetopt correct

# colour in man pages
export GROFF_NO_SGR=1
export MANPAGER='less -F -s -M +Gg'

if [[ -r "$HOME/Development/Projects/kafka-zsh-completions/kafka.plugin.zsh" ]]; then
  source "$HOME/Development/Projects/kafka-zsh-completions/kafka.plugin.zsh"
fi

export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
