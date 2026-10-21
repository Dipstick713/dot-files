#!/usr/bin/env bash
# Phase X — Blur My Shell, overview + dock only (static dock blur; panel stays
# the solid Forest Glass module bar). Settings are written BEFORE install so
# the extension never starts with its defaults (which blur the panel, menus,
# lock screen, ...). Installed through GNOME's own InstallRemoteExtension
# D-Bus call (user-local, loads live after the user confirms GNOME's dialog).
# Idempotent; rollback.sh uninstalls it and resets only these keys.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"

UUID=blur-my-shell@aunetx
B=/org/gnome/shell/extensions/blur-my-shell
fg_set_key X $B/overview/blur "true"
fg_set_key X $B/dash-to-dock/blur "true"
fg_set_key X $B/dash-to-dock/static-blur "true"
for c in panel appfolder applications screenshot lockscreen window-list coverflow-alt-tab popup; do
  fg_set_key X $B/$c/blur "false"
done

if gnome-extensions info "$UUID" >/dev/null 2>&1; then
  fg_log "$UUID already installed"
else
  fg_in_manifest extension "$UUID" || printf 'extension\tX\t%s\n' "$UUID" >> "$FG_MANIFEST"
  fg_log "requesting install of $UUID — confirm the GNOME dialog"
  res="$(gdbus call --session --timeout 180 --dest org.gnome.Shell.Extensions \
          --object-path /org/gnome/Shell/Extensions \
          --method org.gnome.Shell.Extensions.InstallRemoteExtension "$UUID" 2>&1 || true)"
  fg_log "install result: $res"
fi
gnome-extensions info "$UUID" 2>/dev/null | grep -E 'Version|State|Path' || echo "$UUID not installed"
