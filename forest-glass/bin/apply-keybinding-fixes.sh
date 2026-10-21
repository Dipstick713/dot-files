#!/usr/bin/env bash
# Phase K — resolve the shortcut clashes found by shortcuts.py / test-shortcuts.py:
#   * Super+Q closes windows   (Dash to Dock's "show dock" hotkey switched off)
#   * Super+1…9 / Shift+Super+1…9 = workspaces (Dash to Dock number hotkeys off)
#   * Alt+F4 closes windows    (added to close; unbound from power-off)
# Dash to Dock removes its own bindings when these are switched off, and Mutter
# then falls back to the built-in workspace/close bindings. Idempotent.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"
D=/org/gnome/shell/extensions/dash-to-dock
fg_set_key K $D/hotkeys-show-dock "false"
fg_set_key K $D/hot-keys "false"
# Release Alt+F4 from power-off FIRST: when settings-daemon drops its grab it
# also drops a close-window grab registered on the same keys in the meantime.
fg_set_key K /org/gnome/settings-daemon/plugins/media-keys/shutdown "@as []"
sleep 1
# Re-assert close so Mutter (re)grabs Alt+F4 after the release above.
K_CLOSE=/org/gnome/desktop/wm/keybindings/close
fg_set_key K $K_CLOSE "['<Super>q']"
sleep 0.5
fg_set_key K $K_CLOSE "['<Super>q', '<Alt>F4']"
