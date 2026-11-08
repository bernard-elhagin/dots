#!/usr/bin/env bash
set -euo pipefail

DOTS_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/.." && pwd)"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}"
mason_dir="$data_dir/vim-mirror/mason.nvim"

for dependency in nvim git java node npm curl unzip; do
    if ! command -v "$dependency" >/dev/null 2>&1; then
        printf 'Missing language-server installer dependency: %s\n' "$dependency" >&2
        exit 1
    fi
done

# Reuse an existing Mason plugin, otherwise bootstrap a fixed release.
if [[ ! -f "$mason_dir/lua/mason/init.lua" ]]; then
    existing="$data_dir/site/pack/core/opt/mason.nvim"
    if [[ -f "$existing/lua/mason/init.lua" ]]; then
        mason_dir="$existing"
    else
        mkdir -p -- "$(dirname -- "$mason_dir")"
        git clone --depth=1 --branch v2.3.1 https://github.com/mason-org/mason.nvim.git "$mason_dir"
    fi
fi

# Run without the user's init.lua: packages.sh works before install.sh.
DOTS_MASON_DIR="$mason_dir" nvim --headless -u NONE \
    -l "$DOTS_DIR/config/nvim/scripts/install-language-servers.lua"
