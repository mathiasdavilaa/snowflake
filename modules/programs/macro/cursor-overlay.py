#!/usr/bin/env python3
"""Temporary transparent pointer measurement for Niri stable.

This overlay takes pointer focus while running, never keyboard focus. A clean
SIGTERM destroys the surfaces and synchronizes Wayland before process exit,
so callers can click the underlying application after wait() returns.
"""
import json
import signal
import subprocess
import sys
import gi

gi.require_foreign("cairo")
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell


def main():
    initialized, _ = Gtk.init_check([])
    if not initialized:
        print("Não foi possível abrir a sessão gráfica.", file=sys.stderr)
        return 1
    if not GtkLayerShell.is_supported():
        print("A sessão não oferece layer-shell. Execute na sessão Niri.", file=sys.stderr)
        return 1
    screens = json.loads(subprocess.check_output(["niri", "msg", "-j", "outputs"], text=True))
    display = Gdk.Display.get_default()
    windows = []
    mapped = set()

    def report(widget, event, name, logical):
        # Positions from GTK are local logical coordinates of the output surface.
        x, y = event.x, event.y
        if 0 <= x < logical["width"] and 0 <= y < logical["height"]:
            print(f"{name}\t{x:.6f}\t{y:.6f}", flush=True)
        return False

    for i in range(display.get_n_monitors()):
        monitor = display.get_monitor(i)
        g = monitor.get_geometry()
        matches = [(name, out["logical"]) for name, out in screens.items()
                   if out.get("logical") and
                   (out["logical"]["x"], out["logical"]["y"], out["logical"]["width"], out["logical"]["height"]) ==
                   (g.x, g.y, g.width, g.height)]
        if len(matches) != 1:
            print("Não foi possível associar o monitor GTK à saída do Niri.", file=sys.stderr)
            return 1
        name, logical = matches[0]
        mapped.add(name)
        window = Gtk.Window(type=Gtk.WindowType.TOPLEVEL)
        window.set_title("snowflake-cursor-measure")
        window.set_app_paintable(True)
        window.set_visual(window.get_screen().get_rgba_visual())
        window.set_accept_focus(False)
        GtkLayerShell.init_for_window(window)
        GtkLayerShell.set_namespace(window, "snowflake-cursor-measure")
        GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_monitor(window, monitor)
        GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.NONE)
        GtkLayerShell.set_exclusive_zone(window, -1)
        for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM, GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
            GtkLayerShell.set_anchor(window, edge, True)
        window.add_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK)
        window.connect("motion-notify-event", report, name, logical)
        window.connect("enter-notify-event", report, name, logical)
        window.connect("draw", lambda w, cr: (cr.set_operator(0), cr.paint(), True)[-1])
        windows.append(window)

    if not windows:
        print("Nenhum monitor disponível.", file=sys.stderr)
        return 1
    if mapped != {n for n, out in screens.items() if out.get("logical")}:
        print("A lista de monitores GTK difere da lista do Niri. Execute novamente.", file=sys.stderr)
        return 1

    def quit_cleanly():
        for window in windows:
            window.destroy()
        # Process all surface destruction before ydotool can send a click.
        display.flush()
        display.sync()
        Gtk.main_quit()
        return GLib.SOURCE_REMOVE

    def monitors_changed(*args):
        print("Monitores alterados. Execute o comando novamente.", file=sys.stderr)
        quit_cleanly()

    display.connect("monitor-added", monitors_changed)
    display.connect("monitor-removed", monitors_changed)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, quit_cleanly)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, quit_cleanly)
    for window in windows:
        window.show_all()
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
