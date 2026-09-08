# Add Water

Native Nix package of [Add Water](https://github.com/largestgithubuseronearth/addwater)
1.3, an installer and configuration app for the Firefox GNOME Theme. Built directly
from the pinned upstream release with Meson, Python, GTK 4, and libadwaita. No
Flatpak runtime is required.

```sh
nix run github:soltros/soltros_nixpkgs#addwater
```

With this repository's overlay enabled, add `pkgs.addwater` to
`environment.systemPackages` or `home.packages`. An Applications-menu entry is
included. Unlike the development build, this package uses the stable
`dev.qwery.AddWater` app ID and settings schemas.

The package retains upstream browser discovery, including Firefox, LibreWolf,
Floorp, and Waterfox. A browser must have been run at least once to create its
profile. Flatpak browser profiles remain supported even though Add Water itself
runs natively.

## Native integration

- Uses `XDG_CONFIG_HOME` for native browser profiles, while preserving upstream's
  `HOST_XDG_CONFIG_HOME` override.
- Uses an absolute Nix executable path for upstream's portal-based background
  update request. Background scheduling depends on the desktop's portal backend.
- Bundles Python dependencies and wraps the GTK resources, introspection libraries,
  and settings schemas so launching does not depend on a development shell.

This installs the app; it does not apply a browser theme or change any profiles
until you use Add Water. Theme downloads still happen at runtime through the
upstream app.

## Validation

```sh
nix build .#addwater
nix flake check
```

The build validates desktop metadata and schemas, checks the installed command's
help, and opens the actual GTK interface under Xvfb with temporary XDG directories,
in-memory GSettings, a synthetic Firefox profile, and network requests disabled.
The smoke test also loads the preferences dialog and libportal bindings. It does
not test live theme downloads or grant background/autostart permissions.
