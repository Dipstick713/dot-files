#!/usr/bin/env bash
# Phase T — drop non-functional entries from GNOME's enabled-extensions list:
# x11gestures (X11-only, OUT OF DATE on GNOME 50) and two uninstalled leftovers.
# No files, packages or settings are deleted. Recorded per-UUID (kind
# "extoff") so rollback re-adds just these, without clobbering later changes.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"
KEY=/org/gnome/shell/enabled-extensions
for uuid in x11gestures@joseexposito.github.io custom-accent-colors@demiskp openbar@neuromorph; do
  cur="$(dconf read "$KEY")"
  if [[ "$cur" != *"'$uuid'"* ]]; then fg_log "$uuid not in list"; continue; fi
  fg_in_manifest extoff "$uuid" || printf 'extoff\tT\t%s\n' "$uuid" >> "$FG_MANIFEST"
  new="$(python3 -I -c 'import sys,ast; l=ast.literal_eval(sys.argv[1].replace("@as ","")); print(repr([x for x in l if x!=sys.argv[2]]))' "$cur" "$uuid")"
  dconf write "$KEY" "$new"
  fg_log "removed $uuid from enabled-extensions"
done
