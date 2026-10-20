#!/usr/bin/env bash
# Phase W — Waybar-style panel modules (round 2). Supporting changes for the
# module styling in src/forest-glass-shell.css:
#   1. symbolic copies of Pamac's tray icons so the theme can tint them mint
#   2. battery percentage shown next to the battery icon (like the reference)
#   3. one-line System Monitor patch adding smp-metric-<id> classes so each
#      metric can carry its own colour (takes effect after logout/login)
# Idempotent; every change is recorded in the backup manifest.
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"

# 1. Pamac symbolic icons. Placed in a user-local overlay of Papirus-Dark
#    (inherited by Papirus-Dark-Maia) because icon lookup walks the theme
#    chain before hicolor, so a hicolor copy would never be reached.
ICON_DIR="$HOME/.local/share/icons/Papirus-Dark/16x16/symbolic/status"
for n in pamac-tray-no-update pamac-tray-update; do
  src="/usr/share/icons/Papirus/16x16/panel/$n.svg"
  dest="$ICON_DIR/$n-symbolic.svg"
  [ -f "$src" ] || { echo "missing $src" >&2; continue; }
  tmp="$(mktemp)"
  # Same artwork, standard symbolic grey; St recolours symbolic icons via CSS.
  sed -e 's/color:#dfdfdf/color:#bebebe/; s/color:#4285f4/color:#bebebe/' "$src" > "$tmp"
  if cmp -s "$tmp" "$dest"; then rm -f "$tmp"; continue; fi
  fg_track_file W "$dest"
  mkdir -p "$ICON_DIR"; install -m 644 "$tmp" "$dest"; rm -f "$tmp"
  fg_mark_file "$dest"; fg_log "installed $dest"
done

# 2. Battery percentage.
fg_set_key W /org/gnome/desktop/interface/show-battery-percentage "true"

# 3. System Monitor: tag each panel metric box with its id.
EXT="$HOME/.local/share/gnome-shell/extensions/system-monitor-panel@naimur/extension.js"
ANCHOR="            const box = this._createMetricBox(gicon, '—', PANEL_WIDTH_TEMPLATES[id]);"
PATCH="            box.container.add_style_class_name(\`smp-metric-\${id}\`); // Forest Glass: per-metric colours"
if grep -qF "smp-metric-\${id}" "$EXT"; then
  fg_log "System Monitor patch already present"
elif [ "$(grep -cF "$ANCHOR" "$EXT")" = 1 ]; then
  fg_track_file W "$EXT"
  python3 -I - "$EXT" "$ANCHOR" "$PATCH" <<'EOF'
import sys
p, anchor, patch = sys.argv[1:4]
s = open(p).read()
s = s.replace(anchor + "\n", anchor + "\n" + patch + "\n", 1)
open(p, 'w').write(s)
EOF
  # Syntax-check as an ES module; revert on failure so the extension can't break.
  chk="$(mktemp --suffix=.mjs)"; cp "$EXT" "$chk"
  if command -v node >/dev/null && ! node --check "$chk" >/dev/null 2>&1; then
    rm -f "$chk"; fg_revert_file "$EXT"; echo "patched file failed syntax check; reverted" >&2; exit 1; fi
  rm -f "$chk"
  fg_mark_file "$EXT"; fg_log "patched System Monitor (active after logout/login)"
else
  echo "System Monitor code changed upstream; patch skipped (metrics keep the mint fallback)" >&2
fi

# 4. System Monitor stylesheet: managed block between markers, replaced in
#    place on every run. Lives in the extension's own file because St ranks
#    extension stylesheets above the shell theme for their widgets.
SMP_CSS="$HOME/.local/share/gnome-shell/extensions/system-monitor-panel@naimur/stylesheet.css"
python3 -I "$FG_HOME/bin/validate-st-css.py" "$FG_HOME/src/system-monitor-panel.css" >/dev/null || {
  echo "src/system-monitor-panel.css failed validation" >&2; exit 1; }
tmp="$(mktemp)"
python3 -I - "$SMP_CSS" "$FG_HOME/src/system-monitor-panel.css" "$tmp" <<'PY'
import sys, re
css, block, out = sys.argv[1:4]
s = open(css).read(); b = open(block).read().rstrip() + "\n"
start = "/* >>> Forest Glass — managed by ~/.config/forest-glass/bin/apply-waybar-modules.sh >>> */\n"
end = "/* <<< Forest Glass <<< */\n"
s = re.sub(re.escape(start) + r".*?" + re.escape(end), "", s, flags=re.S).rstrip() + "\n"
open(out, "w").write(s + "\n" + start + b + end)
PY
if ! cmp -s "$tmp" "$SMP_CSS"; then
  python3 -I "$FG_HOME/bin/validate-st-css.py" "$tmp" >/dev/null || { rm -f "$tmp"; echo "merged stylesheet invalid" >&2; exit 1; }
  fg_track_file W "$SMP_CSS"
  install -m 644 "$tmp" "$SMP_CSS"; fg_mark_file "$SMP_CSS"
  fg_log "updated System Monitor stylesheet block"
  # Reload the extension so GNOME re-reads its stylesheet (it is re-enabled
  # immediately; its JS is cached until logout, its CSS is not).
  UUID=system-monitor-panel@naimur
  gnome-extensions disable "$UUID" && sleep 1 && gnome-extensions enable "$UUID"
  sleep 1; gnome-extensions info "$UUID" | grep -q 'State: ACTIVE' || echo "WARNING: $UUID not ACTIVE after reload" >&2
fi
rm -f "$tmp"

# 5. Space Bar (its own settings — the theme cannot override its stylesheet):
#    plain mint numbers, active workspace a solid lime block, square corners,
#    monospace via Space Bar's supported custom-styles box.
SB=/org/gnome/shell/extensions/space-bar/appearance
fg_set_key W $SB/inactive-workspace-background-color "'rgba(0,0,0,0)'"
fg_set_key W $SB/active-workspace-border-radius "0"
fg_set_key W $SB/inactive-workspace-border-radius "0"
fg_set_key W $SB/active-workspace-border-width "0"
fg_set_key W $SB/inactive-workspace-border-width "0"
fg_set_key W $SB/active-workspace-padding-h "7"
fg_set_key W $SB/inactive-workspace-padding-h "7"
fg_set_key W $SB/workspace-margin "1"
fg_set_key W $SB/custom-styles "'.space-bar-workspace-label {\n  font-family: \"JetBrainsMono Nerd Font\", monospace;\n  font-size: 11px;\n}'"
fg_set_key W $SB/custom-styles-enabled "true"

# 6. ArcMenu launcher icon in the launcher module colour.
A=/org/gnome/shell/extensions/arcmenu
fg_set_key W $A/menu-button-fg-color "(true, 'rgb(32,201,107)')"
fg_set_key W $A/menu-button-hover-fg-color "(true, 'rgb(32,201,107)')"
fg_set_key W $A/menu-button-active-fg-color "(true, 'rgb(183,243,74)')"
