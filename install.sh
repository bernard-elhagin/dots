#!/bin/bash

#
# Utils
#

# Change to the dots directory
cd "$HOME/dots" || exit

#
# Actual symlink stuff
#

# VIM
echo -n "Copying VIM settings.."
if [[ -d $HOME/.vim ]]; then
    echo "$HOME/.vim already exists...skipping."
else
    ln -s "$HOME/dots/vim" "$HOME/.vim"
    echo "done."
fi

# Neovim
echo -n "Copying Neovim settings.."
if [[ -d $HOME/.config/nvim ]]; then
    echo "$HOME/.config/nvim already exists...skipping."
else
    ln -s "$HOME/dots/config/nvim" "$HOME/.config/nvim"
    echo "done."
fi

# Lunarvim
echo -n "Copying Lunarvim settings.."
if [[ -d $HOME/.config/lvim ]]; then
    rm -rf $HOME/.config/lvim
    ln -s "$HOME/dots/config/lvim" "$HOME/.config/lvim"
    echo "done."
else
    ln -s "$HOME/dots/config/lvim" "$HOME/.config/lvim"
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

# tmuxinator
echo -n "Copying tmuxinator settings.."
if [[ -d $HOME/.tmuxinator ]]; then
    echo "$HOME/.tmuxinator already exists...skipping."
else
    ln -s "$HOME/dots/tmuxinator" "$HOME/.tmuxinator"
    echo "done."
fi

# i3
echo -n "Copying i3 settings.."
if [[ -d $HOME/.i3 ]]; then
    echo "$HOME/.i3 already exists...skipping."
else
    ln -s "$HOME/dots/i3" "$HOME/.i3"
    echo "done."
fi

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

  local i=''
  local sourceFile=''
  local targetFile=''

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  for i in "${FILES_TO_SYMLINK[@]}"; do

    sourceFile="$(pwd)/$i"
    targetFile="$HOME/.$(printf "%s" "$i" | sed "s/.*\/\(.*\)/\1/g")"

    ln -fs "$sourceFile" "$targetFile"

  done

  unset FILES_TO_SYMLINK
}

main

mkdir $HOME/.fzf
cp $HOME/dots/fzf/*.zsh $HOME/.fzf
