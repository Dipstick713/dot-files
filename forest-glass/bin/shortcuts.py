#!/usr/bin/env python3
"""Collect the live keyboard shortcuts of this GNOME session, check them, and
write a cheatsheet.

  shortcuts.py [--md FILE] [--json FILE] [--tested RESULTS.json]

Reads effective values (user overrides AND schema defaults) from GNOME (wm,
shell, mutter, media keys + custom commands) and the shortcut-owning
extensions (Forge, ArcMenu, Space Bar, Dash to Dock). Static checks:
  * every accelerator parses (GTK's own parser)
  * no accelerator is bound to two different actions
  * custom-shortcut commands exist on $PATH
  * the extension that owns a binding is ACTIVE
  * keys that need a numeric keypad are flagged
Exit status 1 if any check fails.
"""
import json
import os
import re
import shutil
import subprocess
import sys
from collections import defaultdict

import ctypes
import ctypes.util
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gio, Gtk  # noqa: E402

HOME = os.path.expanduser('~')
EXT_DIRS = [f'{HOME}/.local/share/gnome-shell/extensions', '/usr/share/gnome-shell/extensions']

# (schema id, group label, owning extension uuid or None, schema dir or None)
SOURCES = [
    ('org.gnome.desktop.wm.keybindings', 'Windows & workspaces (GNOME)', None),
    ('org.gnome.shell.keybindings', 'Shell (GNOME)', None),
    ('org.gnome.mutter.keybindings', 'Tiling & monitors (Mutter)', None),
    ('org.gnome.mutter.wayland.keybindings', 'Wayland session (Mutter)', None),
    ('org.gnome.settings-daemon.plugins.media-keys', 'System, media & launchers', None),
    ('org.gnome.shell.extensions.forge.keybindings', 'Forge tiling', 'forge@jmmaranan.com'),
    ('org.gnome.shell.extensions.arcmenu', 'ArcMenu launcher', 'arcmenu@arcmenu.com'),
    ('org.gnome.shell.extensions.space-bar.shortcuts', 'Space Bar workspaces', 'space-bar@luchrioh'),
    ('org.gnome.shell.extensions.dash-to-dock', 'Dash to Dock', 'dash-to-dock@micxgx.gmail.com'),
]
# Non-shortcut string-array keys in extension schemas that must be skipped.
ARCMENU_KEYS = {'arcmenu-hotkey', 'runner-hotkey'}
DOCK_KEY_RE = re.compile(r'^(app-hotkey|app-shift-hotkey|app-ctrl-hotkey|shortcut)(-\d+)?$')


def schema_source():
    src = Gio.SettingsSchemaSource.get_default()
    for base in EXT_DIRS:
        for uuid in ('dash-to-dock@micxgx.gmail.com', 'forge@jmmaranan.com', 'space-bar@luchrioh', 'arcmenu@arcmenu.com'):
            d = os.path.join(base, uuid, 'schemas')
            if os.path.exists(os.path.join(d, 'gschemas.compiled')):
                src = Gio.SettingsSchemaSource.new_from_directory(d, src, False)
    return src


def ext_state(uuid):
    if not uuid:
        return 'built-in'
    out = subprocess.run(['gnome-extensions', 'info', uuid], capture_output=True, text=True).stdout
    m = re.search(r'State: (\S+)', out)
    return m.group(1) if m else 'NOT INSTALLED'


def pretty(accel):
    a = accel
    for raw, nice in (('<Super>', 'Super+'), ('<Shift>', 'Shift+'), ('<Control>', 'Ctrl+'),
                      ('<Primary>', 'Ctrl+'), ('<Alt>', 'Alt+'), ('<Ctrl>', 'Ctrl+')):
        a = a.replace(raw, nice)
    a = re.sub(r'^Super_L$', 'Super (tap)', a)
    return a


_xkb = ctypes.CDLL(ctypes.util.find_library('xkbcommon'))
_xkb.xkb_keysym_from_name.restype = ctypes.c_uint32
_xkb.xkb_keysym_from_name.argtypes = [ctypes.c_char_p, ctypes.c_int]
_MODS = {'super': 'Super', 'shift': 'Shift', 'control': 'Ctrl', 'ctrl': 'Ctrl', 'primary': 'Ctrl',
         'alt': 'Alt', 'meta': 'Meta', 'hyper': 'Hyper'}
MUTTER_SPECIAL = {'Above_Tab'}   # Mutter resolves this to the key above Tab itself


def norm(accel):
    """Canonical 'Mod+Mod+<keysym>' as Mutter would see it, or None if invalid."""
    mods = []
    rest = accel
    while rest.startswith('<'):
        end = rest.index('>')
        m = _MODS.get(rest[1:end].lower())
        if m is None:
            return None
        mods.append(m)
        rest = rest[end + 1:]
    if not rest:
        return None
    if rest in MUTTER_SPECIAL:
        sym = rest
    else:
        ks = _xkb.xkb_keysym_from_name(rest.encode(), 1)   # 1 = case-insensitive
        if ks == 0:
            return None
        sym = f'0x{ks:x}'
        # Letters: Super+q and Super+Q are the same physical shortcut.
        low = _xkb.xkb_keysym_from_name(rest.lower().encode(), 1)
        if len(rest) == 1 and low:
            sym = f'0x{low:x}'
    return '+'.join(sorted(set(mods)) + [sym])


def collect():
    src = schema_source()
    rows = []
    for sid, group, uuid in SOURCES:
        schema = src.lookup(sid, True)
        if not schema:
            rows.append(dict(group=group, action='(schema not installed)', accels=[], schema=sid,
                             key='', owner=uuid, state=ext_state(uuid), summary=''))
            continue
        settings = Gio.Settings.new_full(schema, None, None)
        state = ext_state(uuid)
        for key in sorted(schema.list_keys()):
            sk = schema.get_key(key)
            vt = sk.get_value_type().dup_string()
            if sid.endswith('arcmenu') and key not in ARCMENU_KEYS:
                continue
            if sid.endswith('dash-to-dock') and not DOCK_KEY_RE.match(key):
                continue
            if vt == 'as':
                accels = list(settings.get_strv(key))
            elif vt == 's' and sid.endswith('media-keys') and key.endswith('-static'):
                continue
            elif vt == 's' and (sid.endswith('media-keys') or sid.endswith('dash-to-dock')):
                v = settings.get_string(key)
                accels = [v] if v else []
            else:
                continue
            if sid.endswith('media-keys') and key == 'custom-keybindings':
                continue
            rows.append(dict(group=group, action=key, accels=[a for a in accels if a],
                             schema=sid, key=key, owner=uuid, state=state,
                             summary=(sk.get_summary() or '').strip()))
    # overlay key
    mut = Gio.Settings.new('org.gnome.mutter')
    rows.append(dict(group='Shell (GNOME)', action='overlay-key', accels=[mut.get_string('overlay-key')],
                     schema='org.gnome.mutter', key='overlay-key', owner=None, state='built-in',
                     summary='Activities overview (or ArcMenu when it claims Super)'))
    # custom shortcuts
    mk = Gio.Settings.new('org.gnome.settings-daemon.plugins.media-keys')
    for path in mk.get_strv('custom-keybindings'):
        c = Gio.Settings.new_with_path('org.gnome.settings-daemon.plugins.media-keys.custom-keybinding', path)
        rows.append(dict(group='Custom commands', action=c.get_string('name'), accels=[c.get_string('binding')],
                         schema='custom-keybinding', key=path, owner=None, state='built-in',
                         summary=c.get_string('command'), command=c.get_string('command')))
    mark_active(rows, src)
    return rows


def _get(src, sid, key):
    sc = src.lookup(sid, True)
    if not sc or not sc.has_key(key):
        return None
    return Gio.Settings.new_full(sc, None, None).get_value(key).unpack()


def mark_active(rows, src):
    """Bindings an extension defines but has switched off don't fire."""
    sb_act = _get(src, 'org.gnome.shell.extensions.space-bar.shortcuts', 'enable-activate-workspace-shortcuts')
    sb_move = _get(src, 'org.gnome.shell.extensions.space-bar.shortcuts', 'enable-move-to-workspace-shortcuts')
    dtd_hot = _get(src, 'org.gnome.shell.extensions.dash-to-dock', 'hot-keys')
    dtd_show = _get(src, 'org.gnome.shell.extensions.dash-to-dock', 'hotkeys-show-dock')
    am_overlay = _get(src, 'org.gnome.shell.extensions.arcmenu', 'arcmenu-hotkey-overlay-key-enabled')
    am_runner_overlay = _get(src, 'org.gnome.shell.extensions.arcmenu', 'runner-hotkey-overlay-key-enabled')
    for r in rows:
        r['active'] = True
        r['note'] = ''
        sid, key = r['schema'], r['key']
        if sid.endswith('space-bar.shortcuts'):
            if key.startswith('activate-') and key.endswith('-key') and not sb_act:
                r['active'] = False; r['note'] = 'Space Bar: workspace shortcuts switched off'
            if key.startswith('move-to-') and not sb_move:
                r['active'] = False; r['note'] = 'Space Bar: move shortcuts switched off'
        if sid.endswith('dash-to-dock'):
            if key.startswith('app-') and not dtd_hot:
                r['active'] = False; r['note'] = 'Dash to Dock hot-keys off'
            if key == 'shortcut' and not (dtd_hot and dtd_show):
                r['active'] = False; r['note'] = 'Dash to Dock show-dock hotkey off'
        if sid.endswith('arcmenu'):
            if key == 'arcmenu-hotkey' and r['accels'] == ['Super_L'] and am_overlay:
                r['note'] = 'ArcMenu takes over the Super key (replaces the overview)'
            if key == 'runner-hotkey' and r['accels'] == ['Super_L'] and am_runner_overlay:
                r['note'] = 'Runner takes over the Super key'
        if sid == 'org.gnome.mutter' and key == 'overlay-key' and am_overlay:
            r['note'] = 'Taken over by ArcMenu (arcmenu-hotkey-overlay-key-enabled)'
        if sid.endswith('dash-to-dock') and key.startswith('app-ctrl-hotkey') and dtd_hot:
            r['note'] = 'replaces GNOME open-new-window-application (same purpose)'
        if sid == 'org.gnome.shell.keybindings' and key.startswith('open-new-window-application') and dtd_hot:
            r['active'] = False; r['note'] = 'replaced by Dash to Dock app-ctrl-hotkey'
        if sid == 'org.gnome.shell.keybindings' and key.startswith('switch-to-application') and dtd_hot:
            r['active'] = False; r['note'] = 'replaced by Dash to Dock app-hotkey'


def check(rows):
    problems = []
    by_accel = defaultdict(list)
    numpad = []
    for r in rows:
        r['issues'] = []
        if r['owner'] and r['state'] != 'ACTIVE' and r['accels']:
            r['issues'].append(f"owner {r['owner']} is {r['state']}")
        for a in r['accels']:
            if a in ('Super_L', 'Super_R'):
                continue          # overlay-key / ArcMenu takeover handled via notes
            n = norm(a)
            if n is None:
                r['issues'].append(f'invalid accelerator {a!r}')
                continue
            if r.get('active', True):
                by_accel[n].append(r)
            if 'KP_' in a:
                numpad.append(r)
        if r.get('command'):
            exe = r['command'].split()[0]
            if not shutil.which(exe):
                r['issues'].append(f'command not found: {exe}')
    conflicts = {}
    for accel, rs in by_accel.items():
        distinct = {(x['schema'], x['key']) for x in rs}
        if len(distinct) > 1:
            conflicts[accel] = rs
            for x in rs:
                others = [f"{y['group']}: {y['action']}" for y in rs if y is not x]
                x['issues'].append('CONFLICT with ' + '; '.join(others))
    problems = [r for r in rows if r['issues']]
    return problems, conflicts, list({id(r): r for r in numpad}.values())


def write_md(rows, problems, conflicts, numpad, path, tested=None):
    groups = defaultdict(list)
    inactive = []
    for r in rows:
        if r['accels'] and r.get('active', True):
            groups[r['group']].append(r)
        elif r['accels']:
            inactive.append(r)
    unbound = sum(1 for r in rows if not r['accels'])
    n_conf = len(conflicts)
    out = ['# Keyboard shortcuts — live cheatsheet', '',
           'Generated from the running session by `~/.config/forest-glass/bin/shortcuts.py`. '
           'Re-run it after changing any binding.', '',
           f'{sum(len(v) for v in groups.values())} bound actions, {unbound} unbound, '
           f'{len(conflicts)} conflicting accelerator(s), {len(numpad)} numpad-only binding(s).', '']
    if tested:
        out += ['## Live test results', '',
                'Typed on a virtual keyboard by `bin/test-shortcuts.py` (safe subset; lock, shutdown and '
                'logout are never sent).', '', '| Keys | Action | Result | Observed |', '|---|---|---|---|']
        icon = {'PASS': '✅ pass', 'FAIL': '❌ fail', 'INFO': 'ℹ️ conflict check', 'SKIP': '⏭ skipped'}
        for t in tested:
            out.append(f"| `{t['keys']}` | {t['action']} | {icon.get(t['status'], t['status'])} | {t['observed']} |")
        out.append('')
    if problems:
        out += ['## Problems found', '']
        for r in problems:
            out.append(f"- **{', '.join(pretty(a) for a in r['accels']) or '—'}** · {r['group']} · "
                       f"`{r['action']}` — {'; '.join(r['issues'])}")
        out.append('')
    order = [s[1] for s in SOURCES] + ['Custom commands']
    for g in sorted(groups, key=lambda x: order.index(x) if x in order else 99):
        out += [f'## {g}', '', '| Shortcut | Action | What it does |', '|---|---|---|']
        for r in sorted(groups[g], key=lambda r: r['action']):
            keys = ' / '.join(f'`{pretty(a)}`' for a in r['accels'])
            flag = ' ⚠️' if r['issues'] else ''
            desc = r['summary'].replace('|', '/') + (f" _({r['note']})_" if r.get('note') else '')
            out.append(f"| {keys}{flag} | {r['action']} | {desc} |")
        out.append('')
    if inactive:
        out += ['## Defined but switched off', '',
                'These are configured but do not fire, because the owning feature is disabled.', '',
                '| Shortcut | Owner / action | Why inactive |', '|---|---|---|']
        for r in sorted(inactive, key=lambda r: (r['group'], r['action'])):
            keys = ' / '.join(f'`{pretty(a)}`' for a in r['accels'])
            out.append(f"| {keys} | {r['group']}: {r['action']} | {r.get('note', '')} |")
        out.append('')
    with open(path, 'w') as f:
        f.write('\n'.join(out))


def main():
    args = sys.argv[1:]
    md = args[args.index('--md') + 1] if '--md' in args else None
    js = args[args.index('--json') + 1] if '--json' in args else None
    rows = collect()
    problems, conflicts, numpad = check(rows)
    tested = None
    if '--tested' in args:
        with open(args[args.index('--tested') + 1]) as f:
            tested = json.load(f)
    if md:
        write_md(rows, problems, conflicts, numpad, md, tested)
    if js:
        with open(js, 'w') as f:
            json.dump(rows, f, indent=1)
    bound = [r for r in rows if r['accels'] and r.get('active', True)]
    print(f'{len(bound)} active bound actions across {len({r["group"] for r in bound})} groups; '
          f'{len(conflicts)} conflict(s); {len(numpad)} numpad binding(s); {len(problems)} with issues')
    for r in problems:
        print(f"  ! {', '.join(pretty(a) for a in r['accels'])}  [{r['group']}] {r['action']}: {'; '.join(r['issues'])}")
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
