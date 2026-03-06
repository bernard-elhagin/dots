# less() color output
export LESS=-iXFR

export EDITOR=vim
export VISUAL=vim

export TERM="xterm-256color"

read -r -d '' paths <<'EOF'
/bin
/home/bertold/bin
/home/bertold/.local/bin
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
EOF

export PATH=$(tr '\n' ':' <<<$paths)

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# History
HISTSIZE=50000
HISTFILE=~/.zshistory
SAVEHIST=$HISTSIZE
HISTDUP=erase
WORDCHARS=""

setopt EXTENDED_GLOB
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Load completions
autoload -U compinit && compinit


# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# colour in man pages
export GROFF_NO_SGR=1
export MANPAGER='less -F -s -M +Gg'

source ~/Projects/kafka-zsh-completions/kafka.plugin.zsh
