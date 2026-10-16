# soltros_nixpkgs

Personal Nix packages with direct flake outputs and a reusable overlay.

## Packages

- `cabinet-desktop` — Native Rust desktop client for self-hosted Cabinet servers
- `chatgpt` — ChatGPT desktop app for Linux
- `flakebuilder` — Build a single NixOS flake from selectable configuration bits
- `flakebuilder-gui` — Optional GTK4/Granite Pantheon frontend for Flakebuilder
- `grayjay` — Cross-platform media application for streaming and downloading media
- `hideout` — Minimal desktop application for GnuPG file encryption and decryption
- `keyguard` — Password manager for Bitwarden and KeePass vaults
- `nixboutique` — Modern GTK4 browser and manager for NixOS applications
- `nixpkger` — CLI manager for NixOS package modules and flakes
- `quick-settings-tray` — AppIndicator and KStatusNotifierItem icons in a contained System Tray section of Quick Settings
- `sharpemu` — Experimental PlayStation 5 emulator (x86_64 Linux)
- `supernova-desktop` — Native Flutter desktop client for self-hosted Supernova music servers
- `termsmith` — Pantheon-native launcher for reusable Alacritty profiles
- `vacuumtube` — YouTube Leanback desktop application with enhancements
- `vpn-manager` — GTK desktop manager for Tailscale and WireGuard ([guide](pkgs/vpn-manager/README.md))
- `vpn-manager-deb` — Debian package artifact for VPN Manager
- `waterfox` — Official Waterfox browser binaries for x86_64 and ARM64 Linux
- `xenia-canary` — Xenia Canary Xbox 360 emulator, compiled from source for x86_64 Linux

`grayjay`, `keyguard`, and `vacuumtube` reuse packages from the pinned nixpkgs input (`vacuumtube` aliases `vacuum-tube`). `default` aliases `termsmith`. Platform support varies by package.

### Additional bundled package sources

These sources are included in the repository but are not currently exported by the flake or overlay:

- `addwater` — Installer and configuration app for the Firefox GNOME Theme ([guide](pkgs/addwater/README.md))
- `pantheon-studio` — Pantheon desktop customization app, with companion launcher and panel packages ([guide](pkgs/pantheon-studio/README.md))

## Run a package

```sh
nix run github:soltros/soltros_nixpkgs#cabinet-desktop
nix run github:soltros/soltros_nixpkgs#nixboutique
nix run github:soltros/soltros_nixpkgs#termsmith
nix run github:soltros/soltros_nixpkgs#chatgpt
nix run github:soltros/soltros_nixpkgs#hideout
nix run github:soltros/soltros_nixpkgs#keyguard
nix run github:soltros/soltros_nixpkgs#grayjay
nix run github:soltros/soltros_nixpkgs#vacuumtube
nix run github:soltros/soltros_nixpkgs#waterfox
nix run github:soltros/soltros_nixpkgs#xenia-canary
nix run github:soltros/soltros_nixpkgs#flakebuilder -- --state-version 26.05
```

Pantheon users can launch the companion frontend with:

```sh
nix run github:soltros/soltros_nixpkgs#flakebuilder-gui
```

Flakebuilder requires `--state-version`, set to the installation's original NixOS release. For an existing system, read it from `/etc/nixos/configuration.nix`:

```sh
grep system.stateVersion /etc/nixos/configuration.nix
```

Additional Flakebuilder options go after the `--` separator, for example:

```sh
nix run github:soltros/soltros_nixpkgs#flakebuilder -- \
  --state-version 26.05 --host workstation --user alice
```

## Add packages to another flake

Declare the input and make it follow the same nixpkgs revision:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  soltros-nixpkgs = {
    url = "github:soltros/soltros_nixpkgs";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Add the overlay in a NixOS module:

```nix
{
  nixpkgs.overlays = [ inputs.soltros-nixpkgs.overlays.default ];

  environment.systemPackages = with pkgs; [
    cabinet-desktop
    chatgpt
    grayjay
    hideout
    keyguard
    nixboutique
    quick-settings-tray
    supernova-desktop
    termsmith
    vacuumtube
    vpn-manager
    waterfox
    alacritty
  ];
}
```

Alternatively, use a package directly without the overlay:

```nix
environment.systemPackages = [
  inputs.soltros-nixpkgs.packages.${pkgs.system}.termsmith
];
```

Because `chatgpt` is unfree, the consuming configuration must also enable:

```nix
nixpkgs.config.allowUnfree = true;
```

## Development

```sh
nix build .#cabinet-desktop
nix build .#chatgpt
nix build .#flakebuilder
nix build .#flakebuilder-gui
nix build .#grayjay
nix build .#hideout
nix build .#keyguard
nix build .#nixboutique
nix build .#nixpkger
nix build .#quick-settings-tray
nix build .#sharpemu
nix build .#supernova-desktop
nix build .#termsmith
nix build .#vacuumtube
nix build .#vpn-manager
nix build .#vpn-manager-deb
nix build .#waterfox
nix build .#xenia-canary
nix flake check
nix fmt
```

## Check for package updates

Run the scanner locally to check for new upstream releases and commits across packages with pinned upstream sources. Bundled applications are reported separately; nixpkgs aliases are updated through `flake.lock`. Xenia Canary is compared with the latest published release tag, and its version, source revision, and hash must be updated together. Commit-pinned packages such as `cabinet-desktop` and `supernova-desktop` are compared with the latest commit on their tracked upstream branches (`main` for Cabinet and `feature/flutter-desktop` for Supernova). The scheduled GitHub workflow updates or opens a `package-updates` issue when a pinned package falls behind:

```sh
# Run via Flake app
nix run github:soltros/soltros_nixpkgs#check-updates

# Or run locally from this repository
./scripts/check-updates.py
```

## Pantheon Studio desktop integration

The companion module and package sources are bundled under `modules/pantheon-studio.nix` and `pkgs/pantheon-studio`, but this flake currently does not export `nixosModules.pantheon-studio` or a `pantheon-studio` package. See [the Studio guide](pkgs/pantheon-studio/README.md) for the source integration details.

## Xenia Canary

`xenia-canary` builds the pinned Canary release and its submodules from source using Clang, CMake, and Ninja. It installs a native executable and desktop launcher. Linux support is experimental; an AVX-capable x86_64 CPU and a Vulkan-capable GPU/driver are required.

```sh
nix run github:soltros/soltros_nixpkgs#xenia-canary -- /path/to/game.xex
```

Configuration, saves, and caches default to `$XDG_DATA_HOME/Xenia` (or `~/.local/share/Xenia`); game paths are passed through unchanged.

The daily package scanner checks published Canary release tags, and Nix CI fetches the source and builds the package.


## Supernova Desktop

`supernova-desktop` is the native Flutter client for Supernova. It connects directly to a self-hosted Supernova instance: enter the instance URL, sign in or register, and the app uses the native Supernova API for library browsing, playback, playlists, favorites, podcasts, radio, and account/server features.

Run it directly:

```sh
nix run github:soltros/soltros_nixpkgs#supernova-desktop
```

Or add it to a NixOS configuration through the overlay:

```nix
environment.systemPackages = with pkgs; [
  supernova-desktop
];
```

The package builds the Flutter client from source and exposes `supernova-desktop` as its main executable.
