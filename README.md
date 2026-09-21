# soltros_nixpkgs

Personal Nix packages with direct flake outputs and a reusable overlay.

## Packages

- `addwater` — Native installer and configuration app for the Firefox GNOME Theme

- `chatgpt` — ChatGPT desktop app for Linux
- `flakebuilder` — Build a single NixOS flake from selectable configuration bits
- `flakebuilder-gui` — Optional GTK4/Granite Pantheon frontend for Flakebuilder
- `grayjay` — Cross-platform media application for streaming and downloading media
- `hideout` — Minimal desktop application for GnuPG file encryption and decryption
- `keyguard` — Password manager for Bitwarden and KeePass vaults
- `nixboutique` — Modern GTK4 browser and manager for NixOS applications
- `quick-settings-tray` — AppIndicator and KStatusNotifierItem icons in a contained System Tray section of Quick Settings
- `supernova-desktop` — Native Flutter desktop client for self-hosted Supernova music servers
- `termsmith` — Pantheon-native launcher for reusable Alacritty profiles
- `vacuumtube` — YouTube Leanback desktop application with enhancements
- `vpn-manager` — GTK desktop manager for Tailscale and WireGuard ([guide](pkgs/vpn-manager/README.md))
- `waterfox` — Official Waterfox browser binaries for x86_64 and ARM64 Linux

## Run a package

```sh
nix run github:soltros/soltros_nixpkgs#addwater
nix run github:soltros/soltros_nixpkgs#pantheon-studio
nix run github:soltros/soltros_nixpkgs#nixboutique
nix run github:soltros/soltros_nixpkgs#termsmith
nix run github:soltros/soltros_nixpkgs#chatgpt
nix run github:soltros/soltros_nixpkgs#hideout
nix run github:soltros/soltros_nixpkgs#keyguard
nix run github:soltros/soltros_nixpkgs#grayjay
nix run github:soltros/soltros_nixpkgs#vacuumtube
nix run github:soltros/soltros_nixpkgs#waterfox
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
    addwater
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
nix build .#chatgpt
nix build .#flakebuilder
nix build .#flakebuilder-gui
nix build .#grayjay
nix build .#hideout
nix build .#keyguard
nix build .#nixboutique
nix build .#quick-settings-tray
nix build .#supernova-desktop
nix build .#termsmith
nix build .#vacuumtube
nix build .#vpn-manager
nix build .#waterfox
nix flake check
nix fmt
```

## Check for package updates

Run the scanner locally to check for new upstream releases and commits across all packaged tools:

```sh
# Run via Flake app
nix run github:soltros/soltros_nixpkgs#check-updates

# Or run locally from this repository
./scripts/check-updates.py
```

## Pantheon Studio desktop integration

For launcher folders, panel customization, and the fix that makes Wingpanel follow
your desktop icon theme, enable the companion module in your NixOS configuration:

```nix
imports = [ inputs.soltros-nixpkgs.nixosModules.pantheon-studio ];
programs.pantheon-studio.enable = true;
```

Update the input, rebuild NixOS, and log out and back in. See
[the Studio guide](pkgs/pantheon-studio/README.md) for features and compatibility.


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
