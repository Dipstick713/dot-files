#!/usr/bin/env bash
# Phase L — Rofi-style launcher: ArcMenu's standalone runner, centered, on
# Super+D (verified free against all GNOME, Forge, Space Bar and ArcMenu
# bindings). Super alone still opens the normal ArcMenu. Idempotent.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"
A=/org/gnome/shell/extensions/arcmenu
fg_set_key L $A/runner-hotkey "['<Super>d']"
fg_set_key L $A/runner-position "'Centered'"
fg_set_key L $A/runner-menu-width "460"
fg_set_key L $A/runner-search-display-style "'List'"
fg_set_key L $A/runner-show-settings-button "false"
