#!/usr/bin/env python3
"""Parse a CSS file with the real GTK CSS parser and report any errors.
Usage: validate-gtk-css.py {3|4} FILE
GTK reports unknown properties, bad values and syntax errors through the
provider's parsing-error signal; any such report fails validation."""
import sys

ver, path = sys.argv[1], sys.argv[2]
import gi
gi.require_version('Gtk', '3.0' if ver == '3' else '4.0')
from gi.repository import Gtk  # noqa: E402

errors = []
provider = Gtk.CssProvider()

if ver == '3':
    provider.connect('parsing-error', lambda _p, section, err: errors.append(
        f'line {section.get_start_line() + 1}: {err.message}'))
    try:
        provider.load_from_path(path)
    except Exception as e:  # GTK 3 also raises on the first error
        errors.append(str(e))
else:
    provider.connect('parsing-error', lambda _p, section, err: errors.append(
        f'{section.to_string()}: {err.message}'))
    provider.load_from_path(path)

for e in dict.fromkeys(errors):
    print(f'{path}: {e}')
print(f'{path}: GTK {ver} parse {"FAILED" if errors else "OK"}')
sys.exit(1 if errors else 0)
