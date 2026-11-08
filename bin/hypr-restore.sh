#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
exec "$SCRIPT_DIR/hypr-session.sh" restore "$@"
