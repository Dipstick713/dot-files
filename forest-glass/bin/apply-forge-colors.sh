#!/usr/bin/env bash
# Phase B — recolor Forge's user stylesheet to Forest Glass.
# Only colour values change; border widths, radii, gaps, keybindings and
# tiling settings are untouched. Idempotent (re-running yields the same file).
set -euo pipefail
source "$HOME/.config/forest-glass/bin/fg-lib.sh"

F="$HOME/.config/forge/stylesheet/forge/stylesheet.css"
[ -f "$F" ] || { echo "Forge stylesheet not found: $F" >&2; exit 1; }
fg_track_file B "$F"

python3 -I - "$F" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()
# selector -> [(property, new value)]
edits = {
    '.tiled':   [('color', 'rgba(32, 201, 107, 1)')],
    '.split':   [('color', 'rgba(183, 243, 74, 1)')],
    '.stacked': [('color', 'rgba(214, 245, 222, 1)')],
    '.tabbed':  [('color', 'rgba(115, 218, 202, 1)')],
    '.floated': [('color', 'rgba(155, 231, 180, 1)')],
    '.window-tiled-border':   [('border-color', 'rgba(32, 201, 107, 0.85)')],
    '.window-split-border':   [('border-color', 'rgba(183, 243, 74, 0.9)')],
    '.window-stacked-border': [('border-color', 'rgba(214, 245, 222, 0.8)')],
    '.window-tabbed-border':  [('border-color', 'rgba(23, 61, 39, 1)')],
    '.window-floated-border': [('border-color', 'rgba(155, 231, 180, 0.85)')],
    '.window-tabbed-tab': [('background-color', 'rgba(16, 21, 16, 0.96)'),
                           ('border-color', 'rgba(214, 245, 222, 0.08)'),
                           ('color', 'rgb(214, 245, 222)')],
    '.window-tabbed-tab-active': [('background-color', 'rgb(23, 61, 39)'),
                                  ('color', 'rgb(183, 243, 74)')],
    '.window-tabbed-tab-close': [('background-color', '#FF7B63')],
    '.window-tilepreview-tiled':   [('border-color', 'rgba(32, 201, 107, 0.45)'),
                                    ('background-color', 'rgba(32, 201, 107, 0.14)')],
    '.window-tilepreview-stacked': [('border-color', 'rgba(214, 245, 222, 0.4)'),
                                    ('background-color', 'rgba(214, 245, 222, 0.12)')],
    '.window-tilepreview-swap':    [('border-color', 'rgba(183, 243, 74, 0.55)'),
                                    ('background-color', 'rgba(183, 243, 74, 0.18)')],
    '.window-tilepreview-tabbed':  [('border-color', 'rgba(23, 61, 39, 0.8)'),
                                    ('background-color', 'rgba(23, 61, 39, 0.35)')],
}
for sel, props in edits.items():
    m = re.search(r'(^|\n)' + re.escape(sel) + r' \{(.*?)\}', s, re.S)
    if not m:
        sys.exit(f'selector not found: {sel}')
    block = m.group(2)
    for prop, val in props:
        block, n = re.subn(r'(\n\s*' + re.escape(prop) + r':)[^;]*;', r'\1 ' + val + ';', block, count=1)
        if n != 1:
            sys.exit(f'property not found: {sel} {prop}')
    s = s[:m.start(2)] + block + s[m.end(2):]
open(p, 'w').write(s)
EOF

python3 -I "$FG_HOME/bin/validate-st-css.py" "$F" >/dev/null || { fg_revert_file "$F"; exit 1; }
fg_mark_file "$F"
# Forge reloads its stylesheet when css-updated changes (this is what its own
# prefs window does after editing colours). Not a behaviour setting.
fg_set_key B /org/gnome/shell/extensions/forge/css-updated "'$(date +%s%3N)'"
fg_log "Forge colours applied"
