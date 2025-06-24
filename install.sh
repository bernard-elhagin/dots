#!/bin/bash

#
# Utils
#

# Change to the dots directory
cd "$HOME/dots" || exit

# VIM
echo -n "Copying VIM settings.."
if [[ -d $HOME/.vim ]]; then
    echo "$HOME/.vim already exists...skipping."
else
    ln -s "$HOME/dots/vim" "$HOME/.vim"
    echo "done."
fi

# bin
echo -n "Copying bin.."
if [[ -d $HOME/bin ]]; then
    echo "$HOME/bin already exists...skipping."
else
    ln -s "$HOME/dots/bin" "$HOME/bin"
    echo "done."
fi

# tmux
echo -n "Copying tmux settings.."
if [[ -d $HOME/.tmux ]]; then
    echo "$HOME/.tmux already exists...skipping."
else
    ln -s "$HOME/dots/tmux" "$HOME/.tmux"
    echo "done."
fi

# i3
echo -n "Copying i3 settings.."
mkdir -p "$HOME/.config/i3"
ln -s "$HOME/dots/i3/config" "$HOME/.config/i3/config"
echo "done."

declare -a FILES_TO_SYMLINK=(
    'zprezto/runcoms/zlogin'
    'zprezto/runcoms/zlogout'
    'zprezto/runcoms/zpreztorc'
    'zprezto/runcoms/zprofile'
    'zprezto/runcoms/zshenv'
    'zprezto/runcoms/zshrc'
    'fzf.sh'
    'vimrc'
    'tmux/tmux.conf'
    'zsh/functions'
    'zsh/aliases.zsh'
    'zsh/aliases_work.zsh'
    'git/gitconfig'
    'git/gitignore'
    'config/starship.toml'
)

for i in "${FILES_TO_SYMLINK[@]}"; do

    sourceFile="$(pwd)/$i"
    targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"

    ln -fs "$sourceFile" "$targetFile"

done

mkdir $HOME/.fzf

cp $HOME/dots/fzf/*.zsh $HOME/.fzf
