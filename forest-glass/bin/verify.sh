#!/usr/bin/env bash
# Forest Glass — post-change verification. Read-only; safe to run any time.
# Compares the live system against the snapshots taken before the rice.
set -uo pipefail
FG_HOME="$HOME/.config/forest-glass"
BK="$(cat "$FG_HOME/current-backup")"
fail=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$*"; fail=1; }
note() { printf '  \033[33mNOTE\033[0m %s\n' "$*"; }

echo "Wallpaper"
sha256sum -c --quiet "$BK/snapshots/wallpaper.sha256" 2>/dev/null && ok "wallpaper file unchanged (sha256)" || bad "wallpaper file changed or missing"
now="$(gsettings get org.gnome.desktop.background picture-uri; gsettings get org.gnome.desktop.background picture-uri-dark;
       gsettings get org.gnome.desktop.background picture-options; gsettings get org.gnome.desktop.screensaver picture-uri)"
[ "$now" = "$(cat "$BK/snapshots/wallpaper-settings.txt")" ] && ok "wallpaper settings unchanged" || bad "wallpaper settings differ"

echo "Forge and shortcuts"
cur="$(dconf dump /org/gnome/shell/extensions/forge/; dconf dump /org/gnome/desktop/wm/keybindings/; dconf dump /org/gnome/shell/keybindings/;
       dconf dump /org/gnome/mutter/; dconf dump /org/gnome/settings-daemon/plugins/media-keys/)"
d="$(diff <(grep -v '^css-updated=' "$BK/snapshots/keybindings-and-forge.ini") <(printf '%s\n' "$cur" | grep -v '^css-updated='))"
[ -z "$d" ] && ok "Forge settings, Forge/WM/shell/media keybindings identical to pre-rice snapshot (css-updated reload stamp excluded)" \
            || { bad "keybinding/Forge differences:"; echo "$d" | sed 's/^/      /'; }
gnome-extensions info forge@jmmaranan.com 2>/dev/null | grep -q 'State: ACTIVE' && ok "Forge extension ACTIVE" || bad "Forge not active"
[ "$(dconf read /org/gnome/shell/extensions/forge/tiling-mode-enabled)" = true ] && ok "Forge tiling enabled" || bad "Forge tiling not enabled"

echo "Extensions"
# Extensions this task installed itself (manifest kind "extension") are expected additions.
added="$(awk -F'\t' '$1=="extension"{print $3}' "$BK/MANIFEST.tsv")"
d="$(diff <(sort "$BK/snapshots/enabled-extensions.txt") <(gnome-extensions list --enabled | grep -vxF -f <(printf '%s\n' $added) | sort))"
[ -z "$d" ] && ok "enabled-extension set unchanged${added:+ (plus installed by this task: $added)}" || { bad "enabled extensions differ:"; echo "$d" | sed 's/^/      /'; }
while read -r uuid; do
  st="$(gnome-extensions info "$uuid" 2>/dev/null | sed -n 's/.*State: //p')"
  case "$st" in ACTIVE) ;; *) note "$uuid state: ${st:-not installed}";; esac
done < <(gnome-extensions list --enabled)

echo "System monitor indicators"
SMP="$HOME/.local/share/gnome-shell/extensions/system-monitor-panel@naimur/schemas"
for m in cpu memory disk temperature network; do
  v="$(gsettings --schemadir "$SMP" get org.gnome.shell.extensions.system-monitor-panel show-$m 2>/dev/null)"
  [ "$v" = true ] && ok "show-$m = true" || bad "show-$m = ${v:-unreadable}"
done
df -h / | awk 'NR==2{print "  INFO root disk " $5 " used (" $4 " free)"}'

echo "Themes and CSS"
[ "$(dconf read /org/gnome/shell/extensions/user-theme/name)" = "'ForestShell'" ] && ok "shell theme = ForestShell" || bad "shell theme changed"
python3 -I "$FG_HOME/bin/validate-st-css.py" "$HOME/.local/share/themes/ForestShell/gnome-shell/gnome-shell.css" >/dev/null && ok "gnome-shell.css passes St checks" || bad "gnome-shell.css has St issues"
python3 -I "$FG_HOME/bin/validate-st-css.py" "$HOME/.config/forge/stylesheet/forge/stylesheet.css" >/dev/null && ok "Forge stylesheet passes St checks" || bad "Forge stylesheet issues"
python3 -I "$FG_HOME/bin/validate-gtk-css.py" 4 "$HOME/.config/gtk-4.0/gtk.css" >/dev/null && ok "gtk-4.0/gtk.css parses (GTK 4)" || bad "gtk-4.0/gtk.css parse errors"
python3 -I "$FG_HOME/bin/validate-gtk-css.py" 3 "$HOME/.config/gtk-3.0/gtk.css" >/dev/null && ok "gtk-3.0/gtk.css parses (GTK 3)" || bad "gtk-3.0/gtk.css parse errors"
grep -q ':has(' "$HOME/.local/share/themes/ForestShell/gnome-shell/gnome-shell.css" && bad "unsupported :has() present" || ok "no unsupported :has() selectors"
dups="$(grep -c 'Forest Glass — GNOME Shell 50 layer' "$HOME/.local/share/themes/ForestShell/gnome-shell/gnome-shell.css")"
[ "$dups" = 1 ] && ok "Forest Glass layer present exactly once" || bad "Forest Glass layer present $dups times"

SMPD="$HOME/.local/share/gnome-shell/extensions/system-monitor-panel@naimur"
n="$(grep -c 'Forest Glass — managed' "$SMPD/stylesheet.css")"
[ "$n" = 1 ] && ok "System Monitor stylesheet: Forest Glass block present once" || bad "System Monitor Forest Glass block count = $n"
python3 -I "$FG_HOME/bin/validate-st-css.py" "$SMPD/stylesheet.css" >/dev/null && ok "System Monitor stylesheet passes St checks" || bad "System Monitor stylesheet issues"
if grep -qF 'smp-metric-${id}' "$SMPD/extension.js"; then
  t="$(mktemp --suffix=.mjs)"; cp "$SMPD/extension.js" "$t"
  node --check "$t" >/dev/null 2>&1 && ok "System Monitor extension.js patch present, syntax OK" || bad "extension.js syntax error"; rm -f "$t"
fi

echo "Dotfiles"
base="$(head -1 "$BK/snapshots/dotfiles-git.txt")"
(cd "$HOME/.dotfiles" && git merge-base --is-ancestor "$base" HEAD \
   && [ -z "$(git diff --name-only "$base" HEAD -- . ':(exclude)forest-glass')" ] \
   && [ -z "$(git status --porcelain -- . ':(exclude)forest-glass')" ]) \
  && ok "~/.dotfiles: original files unchanged (only forest-glass/ added)" \
  || note "~/.dotfiles: files outside forest-glass/ changed since the rice started (not by this task)"

echo "Shell log (since $(date -d '-30 min' '+%H:%M'))"
errs="$(journalctl --user -o cat --since '-30 min' _COMM=gnome-shell 2>/dev/null \
  | grep -iE 'JS ERROR|stylesheet|St\.Theme|parse error|forge@|arcmenu@|user-theme@' | grep -vE '^loading (user|default) theme' | sort -u)"
[ -z "$errs" ] && ok "no theme / Forge / ArcMenu / user-theme errors logged" || { note "log lines to review:"; echo "$errs" | head -15 | sed 's/^/      /'; }

echo; [ $fail = 0 ] && echo "All checks passed." || echo "Some checks FAILED."
exit $fail
