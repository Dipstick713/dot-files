#!/usr/bin/env bash
# Phase D — GTK 3 / GTK 4 / icons / fonts.
# Installs the Forest Glass GTK stylesheets (validated with the real GTK
# parsers first) and sets the matching desktop-interface keys.
# Idempotent: files are replaced from ~/.config/forest-glass/src, never appended.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"

install_css() {  # VERSION SRC DEST
  local ver="$1" src="$2" dest="$3"
  python3 -I "$FG_HOME/bin/validate-gtk-css.py" "$ver" "$src" >/dev/null || {
    python3 -I "$FG_HOME/bin/validate-gtk-css.py" "$ver" "$src"; exit 1; }
  if cmp -s "$src" "$dest"; then fg_log "$(basename "$(dirname "$dest")")/gtk.css up to date"; return; fi
  fg_track_file D "$dest"
  mkdir -p "$(dirname "$dest")"
  install -m 644 "$src" "$dest"
  fg_mark_file "$dest"
  fg_log "installed $dest"
}

install_css 4 "$FG_HOME/src/gtk4.css" "$HOME/.config/gtk-4.0/gtk.css"
install_css 3 "$FG_HOME/src/gtk3.css" "$HOME/.config/gtk-3.0/gtk.css"

I=/org/gnome/desktop/interface
# adw-gtk3-dark (package adw-gtk-theme, already installed) makes GTK 3 apps
# follow the same named colours as libadwaita.
[ -d /usr/share/themes/adw-gtk3-dark ] && fg_set_key D $I/gtk-theme "'adw-gtk3-dark'"
# Same Papirus set, teal-green folders instead of blue (Manjaro variant, installed).
[ -d /usr/share/icons/Papirus-Dark-Maia ] && fg_set_key D $I/icon-theme "'Papirus-Dark-Maia'"
# Match Ghostty's font for GTK monospace text (editors, code views).
grep -q 'JetBrainsMono Nerd Font' < <(fc-list : family) && fg_set_key D $I/monospace-font-name "'JetBrainsMono Nerd Font 11'"
fg_log "GTK phase applied (running GTK 4 apps pick up gtk.css on restart)"
