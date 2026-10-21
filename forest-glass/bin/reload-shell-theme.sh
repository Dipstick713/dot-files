#!/usr/bin/env bash
# Live-reload the GNOME Shell user theme on Wayland (no logout).
# The User Themes extension reloads the stylesheet whenever its `name`
# setting changes, so bounce it off '' and back to the current value.
# Exits 1 if the shell logged stylesheet/theme errors during the reload.
set -euo pipefail
KEY=/org/gnome/shell/extensions/user-theme/name
name="$(dconf read "$KEY")"
[ -n "$name" ] || { echo "no user theme set" >&2; exit 1; }
since="$(date '+%Y-%m-%d %H:%M:%S')"
dconf write "$KEY" "''"
sleep 1
dconf write "$KEY" "$name"
sleep 2
[ "$(dconf read "$KEY")" = "$name" ] || { echo "failed to restore $KEY" >&2; exit 1; }
errs="$(journalctl --user -o cat --since "$since" _COMM=gnome-shell 2>/dev/null \
  | grep -iE 'stylesheet|theme|\.css|St\.Theme|libcroco|parse error' \
  | grep -vE '^loading (user|default) theme' || true)"
if [ -n "$errs" ]; then echo "$errs"; exit 1; fi
echo "[forest-glass] reloaded user theme $name — no stylesheet errors logged"
