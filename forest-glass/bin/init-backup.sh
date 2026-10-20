#!/usr/bin/env bash
# Create a new timestamped backup directory with the pre-rice snapshots that
# verify.sh compares against, and make it the current one. Run this once
# before the apply scripts on a fresh install. Never touches existing backups.
set -euo pipefail
FG_HOME="$HOME/.config/forest-glass"
BK="$HOME/.config/gnome-rice-backups/$(date +%Y%m%d-%H%M%S)"
[ -e "$BK" ] && { echo "$BK already exists" >&2; exit 1; }
mkdir -p "$BK"/{files,dconf,state,snapshots,layers}
touch "$BK/MANIFEST.tsv"

{ dconf dump /org/gnome/shell/extensions/forge/; dconf dump /org/gnome/desktop/wm/keybindings/
  dconf dump /org/gnome/shell/keybindings/; dconf dump /org/gnome/mutter/
  dconf dump /org/gnome/settings-daemon/plugins/media-keys/; } > "$BK/snapshots/keybindings-and-forge.ini"
for p in /org/gnome/shell/ /org/gnome/desktop/interface/ /org/gnome/desktop/background/ \
         /org/gnome/desktop/screensaver/ /org/gnome/desktop/wm/ /org/gnome/mutter/; do
  dconf dump "$p" > "$BK/snapshots/dconf$(echo "$p" | tr / _).ini"
done
wp="$(gsettings get org.gnome.desktop.background picture-uri | sed "s|^'file://||; s|'$||")"
[ -f "$wp" ] && sha256sum "$wp" > "$BK/snapshots/wallpaper.sha256"
{ gsettings get org.gnome.desktop.background picture-uri; gsettings get org.gnome.desktop.background picture-uri-dark
  gsettings get org.gnome.desktop.background picture-options; gsettings get org.gnome.desktop.screensaver picture-uri; } \
  > "$BK/snapshots/wallpaper-settings.txt"
[ -d "$HOME/.dotfiles/.git" ] && (cd "$HOME/.dotfiles" && git rev-parse HEAD && git status --porcelain) > "$BK/snapshots/dotfiles-git.txt"
gnome-extensions list --enabled > "$BK/snapshots/enabled-extensions.txt"
cp -n "$FG_HOME/src/forest-glass-shell.css" "$BK/layers/" 2>/dev/null || true
echo "$BK" > "$FG_HOME/current-backup"
echo "[forest-glass] new backup dir: $BK"
