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
  'make'
  'ripgrep'
  'xsel'
  'fd'
  'tree'
  'unzip'
  'i3-wm'
  'zoxide'
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

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
