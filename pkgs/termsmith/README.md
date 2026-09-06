# Termsmith

Termsmith is a small Pantheon-native launcher for reusable Alacritty terminal
profiles. It is built with GTK 4, Granite 7, and Vala.

Profiles contain a display name, working folder, and optional startup command.
Termsmith stores them in `$XDG_CONFIG_HOME/termsmith/profiles.ini`. The **Create
Shortcut** button writes a corresponding desktop entry to
`$XDG_DATA_HOME/applications`, so it appears in Pantheon's Applications menu.

## Build from the system flake

```sh
nix build .#termsmith
nix run .#termsmith
```

The package is also included in `environment.systemPackages`; applying the
NixOS configuration installs Termsmith and Alacritty system-wide.
