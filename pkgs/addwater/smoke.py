"""Exercise the installed native app with synthetic profiles and no network."""
import gettext
import os
from pathlib import Path
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
gi.require_version("Xdp", "1.0")
from gi.repository import Adw, Gio, GLib, Gtk, Xdp

out = Path(sys.argv[1])
gettext.install("addwater", str(out / "share/locale"))
Gio.Resource.load(str(out / "share/addwater/addwater.gresource"))._register()

from addwater import info
from addwater.apps.firefox.firefox_paths import FirefoxPack
from addwater.apps.firefox.firefox_details import find_profiles, get_valid_packs

assert info.APP_ID == "dev.qwery.AddWater", info.APP_ID
assert info.PROFILE == "default", info.PROFILE
assert FirefoxPack.BASE.path == Path(os.environ["XDG_CONFIG_HOME"]) / "mozilla/firefox"

browser = FirefoxPack.BASE.path
(browser / "fixture.default").mkdir(parents=True)
(browser / "profiles.ini").write_text(
    "[Profile0]\nName = Old fixture\nIsRelative = 1\nPath = fixture.default\nName=Native fixture\nIsRelative=1\nPath=fixture.default\nDefault=1\n"
)
assert FirefoxPack.BASE in get_valid_packs()
profiles = find_profiles(FirefoxPack.BASE)
assert len(profiles) == 1
assert profiles[0].name == "Native fixture"

# Loading the real window must not download or install a theme during this test.
import requests

def offline(*args, **kwargs):
    raise requests.ConnectionError("Network disabled in package smoke test")

requests.sessions.Session.request = offline
from addwater.main import AddWaterApplication
from addwater.preferences import AddWaterPreferences

app = AddWaterApplication()
assert app.register(None)
app.activate()
window = app.get_active_window()
assert isinstance(window, Adw.ApplicationWindow)
preferences = AddWaterPreferences()
assert isinstance(preferences.portal, Xdp.Portal)

loop = GLib.MainLoop()
GLib.timeout_add(500, lambda: (loop.quit(), False)[1])
loop.run()
assert window.get_visible()
assert not (browser / "fixture.default/chrome").exists()
window.close()
app.quit()
print("Native startup, stable schema, libportal, and XDG profile discovery passed.")
