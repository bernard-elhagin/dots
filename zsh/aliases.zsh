# Package manager aliases
alias pacman='pacman --color=always'
alias pac="pacman -Slq | fzf --multi --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
alias yac="yay -Slq | fzf --multi --preview 'yay -Si {1}' | xargs -ro yay -S"
alias yss='yay -Ss'
alias ys='yay -S'
alias pfiles='pacman -Fl'

alias ls='ls --color'
alias  ll='ls -lh --group-directories-first'
alias lll='ls -alh --group-directories-first'
alias zs='vim $HOME/.zshrc'
alias zpre='vim $HOME/.zpreztorc'

alias p='cd ~/Devel/Projects'

alias x='exit'
alias v='vim $(fzf)'

alias gs='git status'
alias gc='git commit'
alias gaa='git add --all'
alias grh='git reset --hard'
alias ga='git commit --amend --no-edit'
alias gcg='git config --global'
alias gcd='cd $(git rev-parse --show-toplevel)'

alias GPF='gaa && ga && gpf'

alias d='cd ~/dots'

alias mci='mvn clean install -DskipTests'

alias c='clear'

# TMUX aliases
alias tml='tmux list-sessions'
alias tma='tmux attach-session -t'
alias tx='tmuxinator start'
alias tm='tmuxinator start $(basename -s .yml $(ls ~/.config/tmuxinator | fzf))'

# Global aliases
alias -g G='| grep --color=always'
alias -g L='| less -r'
alias -g D='2>/dev/null'
alias -g DD='>/dev/null'

alias cll='clear && ll'

alias tl='tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr'

alias l='export JAVA_HOME=/usr/lib/jvm/java-17-openjdk && lvim'

# Kafka
alias kk='docker run -it --network=host edenhill/kcat:1.7.1'

#source ~/.kafka_aliases.zsh

# Check the weather
alias wtr='curl -s wttr.in/gdynia | grep -v igor_chubin'
