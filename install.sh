#!/usr/bin/env bash

set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

backup_path() {
    local destination="$1"
    local timestamp backup suffix

    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup="${destination}.backup-${timestamp}"
    suffix=1

    while [[ -e "$backup" || -L "$backup" ]]; do
        backup="${destination}.backup-${timestamp}-${suffix}"
        ((suffix += 1))
    done

    mv -- "$destination" "$backup"
    printf 'Backed up %s to %s\n' "$destination" "$backup"
}

link_path() {
    local source="$1"
    local destination="$2"
    local destination_dir

    if [[ ! -e "$source" ]]; then
        printf 'Source does not exist: %s\n' "$source" >&2
        return 1
    fi

    if [[ -L "$destination" && "$(readlink -f -- "$destination")" == "$(readlink -f -- "$source")" ]]; then
        printf 'Already linked: %s\n' "$destination"
        return 0
    fi

    destination_dir="$(dirname -- "$destination")"
    mkdir -p -- "$destination_dir"

    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_path "$destination"
    fi

    ln -s -- "$source" "$destination"
    printf 'Linked %s -> %s\n' "$destination" "$source"
}

link_repo_path() {
    local repository_path="$1"
    local home_path="$2"

    link_path "$DOTS_DIR/$repository_path" "$HOME/$home_path"
}

# Directory configurations
link_repo_path vim .vim
link_repo_path zsh .zsh
link_repo_path bin bin
link_repo_path tmux .tmux

# Application configurations
link_repo_path i3/config .config/i3/config
link_repo_path hypr .config/hypr
link_repo_path config/doublecmd .config/doublecmd
link_repo_path config/quickshell .config/quickshell

# Individual dotfiles
declare -a FILES_TO_SYMLINK=(
    'zprezto/runcoms/zlogin:.zlogin'
    'zprezto/runcoms/zlogout:.zlogout'
    'zprezto/runcoms/zpreztorc:.zpreztorc'
    'zprezto/runcoms/zprofile:.zprofile'
    'zprezto/runcoms/zshenv:.zshenv'
    'zprezto/runcoms/zshrc:.zshrc'
    'fzf.sh:.fzf.sh'
    'vimrc:.vimrc'
    'tmux/tmux.conf:.tmux.conf'
    'git/gitconfig:.gitconfig'
    'git/gitignore:.gitignore'
    'config/starship.toml:.starship.toml'
)

for entry in "${FILES_TO_SYMLINK[@]}"; do
    repository_path="${entry%%:*}"
    home_path="${entry#*:}"
    link_repo_path "$repository_path" "$home_path"
done

# fzf's shell integrations are copied into its generated setup directory.
mkdir -p -- "$HOME/.fzf"
cp -- "$DOTS_DIR"/fzf/*.zsh "$HOME/.fzf/"
