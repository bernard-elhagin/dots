# Package manager aliases
alias pacman='pacman --color=always'
alias pac="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias yss='yay -Ss'
alias ys='yay -S'
alias pfiles='pacman -Fl'

alias lll='ls -crtlg'
alias zs='vim $HOME/.zshrc'
alias zpre='vim $HOME/.zpreztorc'
alias github='git clone https://github.com/'

alias p='cd ~/Devel/Projects'

alias x='exit'
alias v='vim $(fzf)'

alias gs='git status'
alias gc='git commit'
alias gaa='git add --all'
alias grh='git reset --hard'
alias ga='git commit --amend --no-edit'

alias GPF='gaa && ga && gpf'

alias d='cd ~/dots'

alias mci='mvn clean install -DskipTests'

alias sshp='ssh el-hbe1@10.111.36.100'

alias c='clear'

# TMUX aliases
alias tml='tmux list-sessions'
alias tma='tmux attach-session -t'
alias tx='tmuxinator start'
alias tmu='tmuxinator start $(basename -s .yml $(ls ~/.tmuxinator | fzf))'

# Global aliases
alias -g G='| grep --color=always'
alias -g L='| less -r'
alias -g D='2>/dev/null'

if (command -v exa >/dev/null); then
    alias ll='exa  -gl --header --time-style=long-iso --group-directories-first --git'
    alias lll='exa -al --header --time-style=long-iso --group-directories-first --git'
fi

alias cll='clear && ll'

alias tl='tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'
