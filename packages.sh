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
)

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

main() {

  local i=''

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  for i in "${PACKAGES_TO_INSTALL[@]}"; do

      echo "pacman -S $i"
      echo -e "\n"
      sudo pacman -S $i

  done

  unset FILES_TO_SYMLINK

}

main

LV_BRANCH='release-1.2/neovim-0.8' bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/fc6873809934917b470bff1b072171879899a36b/utils/installer/install.sh)

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
