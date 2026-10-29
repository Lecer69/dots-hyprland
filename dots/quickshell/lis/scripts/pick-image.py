#!/usr/bin/env python3
# Opens the desktop's file chooser through the XDG portal and prints the path
# of the image picked. Exits 1 when the dialog is cancelled, 2 on an error.
#
# usage: pick-image.py [title]
#
# The portal closes the dialog once the caller leaves the bus, so the call and
# the wait for its answer have to share one connection: gdbus can't do that.

import os
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

PORTAL = "org.freedesktop.portal.Desktop"
PORTAL_PATH = "/org/freedesktop/portal/desktop"


def main():
    title = sys.argv[1] if len(sys.argv) > 1 else "Choose an image"
    loop = GLib.MainLoop()
    result = {"code": 2}

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    except GLib.Error as e:
        print("no session bus:", e.message, file=sys.stderr)
        return 2

    def on_response(_bus, _sender, _path, _iface, _signal, params):
        response, results = params.unpack()
        if response == 0:
            uris = results.get("uris") or []
            path = Gio.File.new_for_uri(uris[0]).get_path() if uris else None
            if path:
                print(path)
                result["code"] = 0
        elif response == 1:
            result["code"] = 1
        loop.quit()

    def subscribe(path):
        bus.signal_subscribe(PORTAL, "org.freedesktop.portal.Request", "Response", path,
                             None, Gio.DBusSignalFlags.NONE, on_response)

    # The request's path is known up front, so the answer can't arrive before
    # the subscription
    token = "lis%d" % os.getpid()
    sender = bus.get_unique_name()[1:].replace(".", "_")
    expected = "%s/request/%s/%s" % (PORTAL_PATH, sender, token)
    subscribe(expected)

    image_types = ["image/png", "image/jpeg", "image/webp", "image/jxl", "image/bmp"]
    options = {
        "handle_token": GLib.Variant("s", token),
        "modal": GLib.Variant("b", True),
        "filters": GLib.Variant("a(sa(us))", [("Images", [(1, t) for t in image_types])]),
    }
    pictures = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_PICTURES)
    if pictures and os.path.isdir(pictures):
        options["current_folder"] = GLib.Variant("ay", pictures.encode() + b"\0")

    try:
        reply = bus.call_sync(PORTAL, PORTAL_PATH, "org.freedesktop.portal.FileChooser", "OpenFile",
                              GLib.Variant("(ssa{sv})", ("", title, options)), GLib.VariantType("(o)"),
                              Gio.DBusCallFlags.NONE, -1, None)
    except GLib.Error as e:
        print("file chooser portal failed:", e.message, file=sys.stderr)
        return 2

    # Portals older than 0.9 pick the path themselves
    handle = reply.unpack()[0]
    if handle != expected:
        subscribe(handle)

    loop.run()
    return result["code"]


if __name__ == "__main__":
    sys.exit(main())
