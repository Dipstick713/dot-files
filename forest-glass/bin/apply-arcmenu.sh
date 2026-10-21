#!/usr/bin/env bash
# Phases A + C — ArcMenu: flat panel button (no capsule outline) and radii
# matching the shell theme. Idempotent; records originals on first run.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"
A=/org/gnome/shell/extensions/arcmenu
fg_set_key A $A/menu-button-border-width "(true, 0)"
fg_set_key A $A/menu-button-bg-color "(true, 'rgba(16,21,16,0)')"
fg_set_key A $A/menu-button-border-radius "(true, 8)"
fg_set_key A $A/menu-button-hover-bg-color "(true, 'rgba(32,201,107,0.14)')"
fg_set_key A $A/menu-button-hover-fg-color "(true, 'rgb(214,245,222)')"
fg_set_key A $A/menu-button-active-bg-color "(true, 'rgba(183,243,74,0.14)')"
fg_set_key A $A/menu-button-active-fg-color "(true, 'rgb(183,243,74)')"
fg_set_key C $A/menu-border-radius "14"
fg_set_key C $A/search-entry-border-radius "(true, 10)"
