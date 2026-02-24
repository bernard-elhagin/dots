# less() color output
export LESS=-iXFR
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\E[1;36m'     # begin blink
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

export EDITOR=vim
export VISUAL=vim

export TERM="xterm-256color"

# History
HISTSIZE=50000
HISTFILE=~/.zsh_history
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
/home/bertold/scripts
/opt/kafka/bin
EOF

export PATH=$(tr '\n' ':' <<<$paths)

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

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

export GREP_COLORS='mt=03;31'

