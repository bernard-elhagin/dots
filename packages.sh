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
    'tmux'
    'zsh'
)

sudo pacman -Sy

for i in "${PACKAGES_TO_INSTALL[@]}"; do

    echo "pacman -S $i"
    echo -e "\n"
    sudo pacman --noconfirm -S $i

done

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

