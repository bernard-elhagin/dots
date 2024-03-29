#!/bin/bash

declare -a PACKAGES_TO_INSTALL=(
  'gvim'
  'neovim'
  'git'
  'fzf'
  'fasd'
  'starship'
  'git-delta'
  'ranger'
  'npm'
  'make'
  'ripgrep'
  'xsel'
  'exa'
  'fd'
  'tree'
  'unzip'
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

  local i=''

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  sudo pacman -Sy

  for i in "${PACKAGES_TO_INSTALL[@]}"; do

      echo "pacman -S $i"
      echo -e "\n"
      sudo pacman --noconfirm -S $i

  done

  unset FILES_TO_SYMLINK

}

main

LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/fc6873809934917b470bff1b072171879899a36b/utils/installer/install.sh)

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
