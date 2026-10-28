#!/usr/bin/env bash
set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
ACTION="${1:-add}"

# Garante o diretório raiz do plugin para resolução de bin/...
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

case "$ACTION" in
  add)
    exec "$HERDR" plugin pane open \
      --plugin "herdr-ssh-machines" \
      --entrypoint "add-machine-picker" \
      --placement popup \
      --cwd "$PLUGIN_ROOT" \
      --focus
    ;;
  remove)
    exec "$HERDR" plugin pane open \
      --plugin "herdr-ssh-machines" \
      --entrypoint "remove-machine-picker" \
      --placement popup \
      --cwd "$PLUGIN_ROOT" \
      --focus
    ;;
  *)
    echo "Ação desconhecida: $ACTION (use 'add' ou 'remove')" >&2
    exit 1
    ;;
esac
