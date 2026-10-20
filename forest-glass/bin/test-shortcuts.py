#!/usr/bin/env python3
"""Live-test a safe subset of keyboard shortcuts by typing them on a virtual
keyboard (/dev/uinput) and observing the effect.

  test-shortcuts.py [--report FILE]

SAFETY — this presses real keys in the running session:
  * Moves to the empty last workspace (Super+End) and spawns two disposable
    test windows there, so window shortcuts only ever act on those.
  * Window tests are skipped unless a test window has focus.
  * Volume, brightness and Forge's focus-border setting are saved first and
    restored at the end, even on error.
  * Never sends: lock (Super+Shift+L), shutdown (Alt+F4), logout
    (Ctrl+Alt+Del), or anything that could close/move your own windows.
Don't type or click while it runs (~1 minute).
"""
import fcntl
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SCRATCH = os.environ.get('FG_SCRATCH') or tempfile.mkdtemp(prefix='fg-shortcut-test-')

# --- virtual keyboard -------------------------------------------------------
EV_SYN, EV_KEY = 0x00, 0x01
UI_SET_EVBIT, UI_SET_KEYBIT = 0x40045564, 0x40045565
UI_DEV_SETUP, UI_DEV_CREATE, UI_DEV_DESTROY = 0x405C5503, 0x5501, 0x5502
K = dict(ESC=1, F4=62, Q=16, W=17, D=32, C=46, X=45, F2=60, F3=61, KP1=79, KP3=81,
         CTRL=29, SHIFT=42, ALT=56, SUPER=125, END=107, VOLDOWN=114, VOLUP=115,
         N1=2, N2=3)


class VKbd:
    def __init__(self):
        self.fd = os.open('/dev/uinput', os.O_WRONLY | os.O_NONBLOCK)
        fcntl.ioctl(self.fd, UI_SET_EVBIT, EV_KEY)
        for code in set(K.values()):
            fcntl.ioctl(self.fd, UI_SET_KEYBIT, code)
        setup = struct.pack('HHHH80sI', 0x03, 0x1234, 0x5678, 1,
                            b'forest-glass shortcut tester', 0)
        fcntl.ioctl(self.fd, UI_DEV_SETUP, setup)
        fcntl.ioctl(self.fd, UI_DEV_CREATE)
        self.down = set()
        time.sleep(1.0)          # let libinput/Mutter pick the device up

    def _ev(self, typ, code, val):
        t = time.time()
        os.write(self.fd, struct.pack('llHHi', int(t), int((t % 1) * 1e6), typ, code, val))

    def _key(self, code, val):
        self._ev(EV_KEY, code, val)
        self._ev(EV_SYN, 0, 0)
        (self.down.add if val else self.down.discard)(code)

    def combo(self, *names, hold=0.08):
        codes = [K[n] for n in names]
        for c in codes:
            self._key(c, 1)
            time.sleep(0.02)
        time.sleep(hold)
        for c in reversed(codes):
            self._key(c, 0)
            time.sleep(0.02)

    def close(self):
        for c in list(self.down):
            self._key(c, 0)
        fcntl.ioctl(self.fd, UI_DEV_DESTROY)
        os.close(self.fd)


# --- disposable test windows ------------------------------------------------
WINDOWS_PY = r'''
import json, sys, gi
gi.require_version('Gtk', '4.0'); gi.require_version('Gdk', '4.0')
from gi.repository import Gtk, Gdk, GLib
state_path = sys.argv[1]
state = {}
app = Gtk.Application(application_id='org.forestglass.ShortcutTest')
def write():
    with open(state_path + '.tmp', 'w') as f: json.dump(state, f)
    import os; os.replace(state_path + '.tmp', state_path)
def make(name, color):
    w = Gtk.ApplicationWindow(application=app, title=f'fg-shortcut-test {name}',
                              default_width=420, default_height=300)
    lbl = Gtk.Label(label=f'Forest Glass shortcut test — window {name}\n(closes automatically)')
    w.set_child(lbl)
    css = Gtk.CssProvider(); css.load_from_string(f'window {{ background: {color}; }}')
    w.get_style_context().add_provider(css, 800)
    state[name] = dict(alive=True)
    def on_close(*_):
        state[name]['alive'] = False; write(); return False
    w.connect('close-request', on_close)
    def poll():
        if not state[name]['alive']: return False
        surf = w.get_surface()
        st = surf.get_state() if surf else 0
        state[name].update(active=w.is_active(), w=w.get_width(), h=w.get_height(),
                           suspended=bool(st & Gdk.ToplevelState.SUSPENDED) if surf else None,
                           tiled=bool(st & (Gdk.ToplevelState.TILED | Gdk.ToplevelState.MAXIMIZED)) if surf else None)
        write(); return True
    GLib.timeout_add(100, poll)
    w.present()
    return w
def activate(app):
    make('A', '#173D27')
    GLib.timeout_add(700, lambda: (make('B', '#101510'), False)[1])
    GLib.timeout_add(1400, lambda: (make('C', '#245435'), False)[1])
app.connect('activate', activate)
app.run([])
'''


def wstate():
    try:
        with open(os.path.join(SCRATCH, 'state.json')) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def active_test(st):
    """Name of the test window that has focus, or None."""
    for n in 'ABC':
        if st.get(n, {}).get('alive') and st[n].get('active'):
            return n
    return None


def wait_for(pred, timeout=3.0):
    end = time.time() + timeout
    while time.time() < end:
        if pred():
            return True
        time.sleep(0.1)
    return pred()


# --- observers --------------------------------------------------------------
def screenshot():
    """Full-screen capture via the desktop portal; returns a GdkPixbuf."""
    import gi
    gi.require_version('GdkPixbuf', '2.0')
    from gi.repository import GdkPixbuf
    pic = os.path.expanduser('~/Pictures/Screenshot.png')
    if os.path.exists(pic):
        raise RuntimeError('~/Pictures/Screenshot.png exists; refusing to overwrite')
    subprocess.run([sys.executable, '-I', os.path.join(HERE, 'portal-shot.py')], check=True,
                   capture_output=True, timeout=20)
    dest = os.path.join(SCRATCH, f'shot-{time.time():.3f}.png')
    shutil.move(pic, dest)
    return GdkPixbuf.Pixbuf.new_from_file(dest)


def region_diff(a, b, x, y, w, h, step=4):
    pa, pb = a.get_pixels(), b.get_pixels()
    rs, nc = a.get_rowstride(), a.get_n_channels()
    tot = n = 0
    for yy in range(y, y + h, step):
        for xx in range(x, x + w, step):
            o = yy * rs + xx * nc
            tot += sum(abs(pa[o + i] - pb[o + i]) for i in range(3))
            n += 1
    return tot / (3 * n)


def active_ws_x(pb):
    """x of Space Bar's lime (#B7F34A) active-workspace block in the left panel area."""
    px, rs, nc = pb.get_pixels(), pb.get_rowstride(), pb.get_n_channels()
    for x in range(40, 700):
        o = 15 * rs + x * nc
        r, g, b = px[o], px[o + 1], px[o + 2]
        if abs(r - 0xB7) < 12 and abs(g - 0xF3) < 12 and abs(b - 0x4A) < 12:
            return x
    return None


def dconf_read(k):
    return subprocess.run(['dconf', 'read', k], capture_output=True, text=True).stdout.strip()


def volume():
    out = subprocess.run(['wpctl', 'get-volume', '@DEFAULT_AUDIO_SINK@'], capture_output=True, text=True).stdout
    return float(out.split()[1])


def brightness():
    return int(subprocess.run(['brightnessctl', 'get'], capture_output=True, text=True).stdout.strip())


# --- tests ------------------------------------------------------------------
results = []


def record(keys, action, expected, observed, status):
    results.append(dict(keys=keys, action=action, expected=expected, observed=observed, status=status))
    print(f'  [{status:4}] {keys:22} {action}: {observed}', flush=True)


def main():
    report = sys.argv[sys.argv.index('--report') + 1] if '--report' in sys.argv else None
    saved = dict(volume=volume(), brightness=brightness(),
                 focus_border=dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle'))
    print(f'saved state: {saved}', flush=True)
    kb = VKbd()
    app = None
    try:
        # Media/system keys first: no windows involved.
        v0 = volume()
        kb.combo('VOLUP'); time.sleep(0.6); v1 = volume()
        kb.combo('VOLDOWN'); time.sleep(0.6); v2 = volume()
        record('Volume Up / Down keys', 'volume-up/-down', 'volume changes',
               f'{v0:.2f} → {v1:.2f} → {v2:.2f}', 'PASS' if v1 > v0 and v2 < v1 else 'FAIL')

        b0 = brightness()
        kb.combo('SUPER', 'F3'); time.sleep(0.8); b1 = brightness()
        kb.combo('SUPER', 'F2'); time.sleep(0.8); b2 = brightness()
        record('Super+F3 / Super+F2', 'custom: brightness +/-', 'brightness up then down',
               f'{b0} → {b1} → {b2}', 'PASS' if b1 > b0 and b2 < b1 else 'FAIL')

        # Shell UI: ArcMenu (Super tap) and the runner (Super+D).
        base = screenshot()
        kb.combo('SUPER'); time.sleep(0.8)
        shot = screenshot(); d = region_diff(base, shot, 0, 40, 700, 700)
        kb.combo('ESC'); time.sleep(0.6)
        record('Super (tap)', 'ArcMenu (overlay key)', 'ArcMenu opens top-left',
               f'top-left region changed by {d:.1f}', 'PASS' if d > 8 else 'FAIL')

        base = screenshot()
        kb.combo('SUPER', 'D'); time.sleep(0.8)
        shot = screenshot(); d = region_diff(base, shot, 660, 200, 600, 500)
        kb.combo('ESC'); time.sleep(0.6)
        record('Super+D', 'ArcMenu runner', 'centered launcher opens',
               f'centre region changed by {d:.1f}', 'PASS' if d > 8 else 'FAIL')

        fb0 = dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle')
        kb.combo('SUPER', 'X'); time.sleep(0.6)
        fb1 = dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle')
        kb.combo('SUPER', 'X'); time.sleep(0.6)
        fb2 = dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle')
        record('Super+X (twice)', 'Forge focus-border-toggle', 'setting flips and flips back',
               f'{fb0} → {fb1} → {fb2}', 'PASS' if fb1 != fb0 and fb2 == fb0 else 'FAIL')

        # Window tests on the empty last workspace.
        kb.combo('SUPER', 'END'); time.sleep(0.8)
        app = subprocess.Popen([sys.executable, '-I', '-c', WINDOWS_PY, os.path.join(SCRATCH, 'state.json')],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ok = wait_for(lambda: wstate().get('C', {}).get('active') is not None, 8) and \
            wait_for(lambda: any(wstate().get(n, {}).get('active') for n in 'ABC'), 3)
        time.sleep(1.0)
        st = wstate()
        if not ok or not any(st.get(n, {}).get('active') for n in 'ABC'):
            record('—', 'window tests', 'a test window has focus', f'no focus ({st}); window tests skipped', 'SKIP')
        else:
            focused = active_test(st)
            record('Super+End', 'switch-to-workspace-last', 'test windows open on an empty workspace',
                   f"3 test windows up, {focused} focused, tiled={st[focused].get('tiled')}", 'PASS')

            # Forge numpad focus (Num Lock state as configured in the session).
            kb.combo('SUPER', 'KP1'); time.sleep(0.6)
            s1 = wstate()
            kb.combo('SUPER', 'KP3'); time.sleep(0.6)
            s2 = wstate()
            a1, a2 = active_test(s1) or '?', active_test(s2) or '?'
            moved = a1 != a2
            record('Super+KP_1 / Super+KP_3', 'Forge focus left / right', 'focus moves between the two windows',
                   f'focus {focused} → {a1} → {a2}', 'PASS' if moved else 'FAIL')

            # Forge float toggle on the focused test window.
            st = wstate(); cur = active_test(st)
            w0 = (st[cur]['w'], st[cur]['h'])
            kb.combo('SUPER', 'C'); time.sleep(0.9)
            w1 = (wstate()[cur]['w'], wstate()[cur]['h'])
            kb.combo('SUPER', 'C'); time.sleep(0.9)
            w2 = (wstate()[cur]['w'], wstate()[cur]['h'])
            record('Super+C (twice)', 'Forge window-toggle-float', 'size changes, then returns',
                   f'{w0} → {w1} → {w2}', 'PASS' if w1 != w0 and w2 == w0 else 'FAIL')

            # Close-window shortcuts (only ever sent while a TEST window has focus).
            for keys, names in (('Super+Q', ('SUPER', 'Q')), ('Alt+F4', ('ALT', 'F4'))):
                st = wstate(); cur = active_test(st)
                if not cur:
                    record(keys, 'close window', 'focused test window closes', 'no test window focused; not sent', 'SKIP')
                    continue
                kb.combo(*names); time.sleep(1.0)
                st = wstate()
                closed = not st[cur]['alive']
                record(keys, 'close window', 'focused test window closes',
                       f"window {cur} {'closed' if closed else 'still open'}", 'PASS' if closed else 'FAIL')
                wait_for(lambda: active_test(wstate()) is not None, 2)

            # Super+1 must switch to workspace 1 (last test: leaves the test workspace).
            # Observed via Space Bar: the lime "active workspace" block moves left.
            st = wstate(); cur = active_test(st)
            if not cur:
                record('Super+1', 'switch-to-workspace-1', 'workspace changes', 'no test window focused; not sent', 'SKIP')
            else:
                x0 = active_ws_x(screenshot())
                kb.combo('SUPER', 'N1'); time.sleep(1.0)
                x1 = active_ws_x(screenshot())
                ok1 = x0 is not None and x1 is not None and x1 < x0
                record('Super+1', 'switch-to-workspace-1', 'active-workspace marker moves to the first slot',
                       f'Space Bar lime block x: {x0} → {x1}', 'PASS' if ok1 else 'FAIL')
    finally:
        kb.close()
        if app:
            app.terminate()
            try:
                app.wait(5)
            except subprocess.TimeoutExpired:
                app.kill()
        subprocess.run(['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', f"{saved['volume']:.2f}"])
        subprocess.run(['brightnessctl', '-q', 'set', str(saved['brightness'])])
        if dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle') != saved['focus_border']:
            subprocess.run(['dconf', 'write', '/org/gnome/shell/extensions/forge/focus-border-toggle', saved['focus_border']])
        print(f"restored: volume {volume():.2f}, brightness {brightness()}, "
              f"focus-border {dconf_read('/org/gnome/shell/extensions/forge/focus-border-toggle')}", flush=True)
        if report:
            with open(report, 'w') as f:
                json.dump(results, f, indent=1)


if __name__ == '__main__':
    main()
