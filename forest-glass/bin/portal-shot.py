#!/usr/bin/env python3
# Non-interactive screenshot via the xdg-desktop-portal; saves to ~/Pictures/Screenshot.png.
import sys, gi
gi.require_version('Gio','2.0')
from gi.repository import Gio, GLib
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
loop = GLib.MainLoop(); out = {}
def on_resp(conn, sender, path, iface, sig, params):
    code, res = params.unpack(); out['code']=code; out['uri']=res.get('uri'); loop.quit()
token = 'fg%d' % GLib.random_int_range(0, 100000)
sender = bus.get_unique_name()[1:].replace('.', '_')
hpath = f'/org/freedesktop/portal/desktop/request/{sender}/{token}'
bus.signal_subscribe('org.freedesktop.portal.Desktop','org.freedesktop.portal.Request','Response',hpath,None,0,on_resp)
bus.call_sync('org.freedesktop.portal.Desktop','/org/freedesktop/portal/desktop','org.freedesktop.portal.Screenshot','Screenshot',
  GLib.Variant('(sa{sv})', ('', {'handle_token': GLib.Variant('s', token), 'interactive': GLib.Variant('b', False)})), None, 0, -1, None)
GLib.timeout_add_seconds(20, loop.quit); loop.run(); print(out)
