#!/usr/bin/env bash
# Forest Glass — roll back changes made by this task, from the backup manifest.
#
#   rollback.sh [--phase A|B|C|D|W|L|X|T|K] [--dry-run] [--force] [--backup DIR]
#
# Phases: A = shell theme file (gnome-shell.css carries the panel, overview and
#             app-grid styling, i.e. A+B+C visuals) + ArcMenu panel button
#         B = Forge stylesheet colours
#         C = ArcMenu menu radius / search radius
#         D = GTK 3/4 gtk.css, gtk-theme, icon-theme, monospace font
#         W = round 2 "Waybar modules": System Monitor stylesheet block +
#             extension.js class patch, Pamac symbolic icons, battery %,
#             Space Bar look, ArcMenu icon colour. (The panel CSS itself is in
#             the phase-A theme file; the round-1 layer is kept at
#             <backup>/layers/forest-glass-shell.round1.css.)
#         L = Super+D launcher (ArcMenu standalone runner)
#         X = Blur My Shell (extension uninstalled, its keys reset)
#         T = enabled-extensions tidy (re-adds the removed UUIDs)
#         K = shortcut fixes (close on Super+Q/Alt+F4, Super+N workspaces)
#
# Safety: only paths/keys listed in MANIFEST.tsv are touched. Each one is
# restored only if it still holds the value this task applied; anything you
# changed afterwards is reported as a CONFLICT and left alone (use --force to
# restore anyway). Backups are never deleted or modified.
set -uo pipefail
FG_HOME="$HOME/.config/forest-glass"
BK="$(cat "$FG_HOME/current-backup" 2>/dev/null)"
PHASE=""; DRY=0; FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --phase) PHASE="$2"; shift ;;
    --dry-run) DRY=1 ;;
    --force) FORCE=1 ;;
    --backup) BK="$2"; shift ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown option $1" >&2; exit 2 ;;
  esac; shift
done
[ -f "$BK/MANIFEST.tsv" ] || { echo "no manifest in $BK" >&2; exit 1; }

id()  { printf '%s' "$1" | sed 's|^/||; s|/|__|g'; }
sha() { [ -e "$1" ] && sha256sum "$1" | cut -d' ' -f1 || echo MISSING; }
act() { if [ $DRY = 1 ]; then echo "  would: $*"; else "$@"; fi; }
restored=0; conflicts=0; skipped=0; shell_css=0; smp_css=0; smp_js=0
DID=restored; [ $DRY = 1 ] && DID="would restore"

echo "Rolling back from $BK${PHASE:+ (phase $PHASE)}$([ $DRY = 1 ] && echo ' [dry run]')"

# Files first (so the Forge reload key restored below picks up the old CSS).
while IFS=$'\t' read -r kind phase target; do
  [ -n "$PHASE" ] && [ "$phase" != "$PHASE" ] && continue
  case "$kind" in file|newfile) ;; *) continue ;; esac
  rel="${target#"$HOME"/}"; i="$(id "$rel")"
  applied="$(cat "$BK/state/$i.applied" 2>/dev/null)"; cur="$(sha "$target")"
  if [ "$kind" = newfile ]; then
    if [ "$cur" = MISSING ]; then echo "  ok       $rel already absent"; skipped=$((skipped+1)); continue; fi
    if [ "$cur" != "$applied" ] && [ $FORCE = 0 ]; then echo "  CONFLICT $rel was modified after the rice; left in place"; conflicts=$((conflicts+1)); continue; fi
    act rm -f -- "$target"; echo "  $DID (remove) $rel"; restored=$((restored+1)); continue
  fi
  orig="$(cat "$BK/state/$i.orig" 2>/dev/null)"
  if [ "$cur" = "$orig" ]; then echo "  ok       $rel already original"; skipped=$((skipped+1)); continue; fi
  if [ "$cur" != "$applied" ] && [ $FORCE = 0 ]; then
    echo "  CONFLICT $rel changed after the rice (current != applied); left alone — compare with $BK/files/$rel"
    conflicts=$((conflicts+1)); continue; fi
  [ -e "$BK/files/$rel" ] || { echo "  MISSING backup for $rel" >&2; conflicts=$((conflicts+1)); continue; }
  act mkdir -p "$(dirname "$target")"
  act cp -a -- "$BK/files/$rel" "$target"
  echo "  $DID $rel"; restored=$((restored+1))
  [[ "$target" == */gnome-shell/gnome-shell.css ]] && shell_css=1
  [[ "$target" == */system-monitor-panel@naimur/stylesheet.css ]] && smp_css=1
  [[ "$target" == */system-monitor-panel@naimur/extension.js ]] && smp_js=1
done < "$BK/MANIFEST.tsv"

# Extensions this task installed: uninstall them (GNOME removes the files).
while IFS=$'\t' read -r kind phase uuid; do
  [ -n "$PHASE" ] && [ "$phase" != "$PHASE" ] && continue
  [ "$kind" = extension ] || continue
  if ! gnome-extensions info "$uuid" >/dev/null 2>&1; then echo "  ok       $uuid already absent"; skipped=$((skipped+1)); continue; fi
  act gnome-extensions uninstall "$uuid"
  cur="$(dconf read /org/gnome/shell/enabled-extensions)"
  if [[ "$cur" == *"'$uuid'"* ]]; then
    new="$(python3 -I -c 'import sys,ast; l=ast.literal_eval(sys.argv[1].replace("@as ","")); print(repr([x for x in l if x!=sys.argv[2]]))' "$cur" "$uuid")"
    act dconf write /org/gnome/shell/enabled-extensions "$new"
  fi
  echo "  $DID (uninstall) $uuid"; restored=$((restored+1))
done < "$BK/MANIFEST.tsv"

# Entries removed from enabled-extensions: add each back if it is missing.
while IFS=$'\t' read -r kind phase uuid; do
  [ -n "$PHASE" ] && [ "$phase" != "$PHASE" ] && continue
  [ "$kind" = extoff ] || continue
  cur="$(dconf read /org/gnome/shell/enabled-extensions)"
  if [[ "$cur" == *"'$uuid'"* ]]; then echo "  ok       $uuid already enabled"; skipped=$((skipped+1)); continue; fi
  new="$(python3 -I -c 'import sys,ast; v=sys.argv[1].replace("@as ","") or "[]"; l=ast.literal_eval(v); print(repr(l+[sys.argv[2]]))' "$cur" "$uuid")"
  act dconf write /org/gnome/shell/enabled-extensions "$new"
  echo "  $DID (re-enable) $uuid"; restored=$((restored+1))
done < "$BK/MANIFEST.tsv"

# Then dconf keys.
while IFS=$'\t' read -r kind phase key; do
  [ -n "$PHASE" ] && [ "$phase" != "$PHASE" ] && continue
  [ "$kind" = dconf ] || continue
  i="$(id "$key")"; orig="$(cat "$BK/dconf/$i.orig")"; applied="$(cat "$BK/dconf/$i.applied")"; cur="$(dconf read "$key")"
  if [ "$cur" = "$orig" ]; then echo "  ok       $key already original"; skipped=$((skipped+1)); continue; fi
  if [ "$cur" != "$applied" ] && [ $FORCE = 0 ]; then
    echo "  CONFLICT $key = $cur (changed after the rice; original was ${orig:-<unset>})"; conflicts=$((conflicts+1)); continue; fi
  if [ -z "$orig" ]; then act dconf reset "$key"; else act dconf write "$key" "$orig"; fi
  echo "  $DID $key = ${orig:-<default>}"; restored=$((restored+1))
done < "$BK/MANIFEST.tsv"

if [ $shell_css = 1 ] && [ $DRY = 0 ]; then
  "$FG_HOME/bin/reload-shell-theme.sh" || echo "  note: shell theme reload logged messages; check journalctl"
fi
if [ $smp_css = 1 ] && [ $DRY = 0 ]; then
  gnome-extensions disable system-monitor-panel@naimur && sleep 1 && gnome-extensions enable system-monitor-panel@naimur
  echo "  reloaded system-monitor-panel@naimur (stylesheet)"
fi
[ $smp_js = 1 ] && echo "  NOTE: extension.js restored — log out and back in for GNOME to load it"
echo "Done: $restored restored, $skipped already original, $conflicts conflict(s). Backups kept in $BK."
[ $conflicts = 0 ]
