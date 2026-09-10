# soltros_nixpkgs

Personal Nix packages with direct flake outputs and a reusable overlay.

## Packages

- `addwater` — Native installer and configuration app for the Firefox GNOME Theme

- `chatgpt` — ChatGPT desktop app for Linux
- `flakebuilder` — Build a single NixOS flake from selectable configuration bits
- `pantheon-studio` — Native Pantheon launcher folders, panel customization, icon themes, and application editing
- `termsmith` — Pantheon-native launcher for reusable Alacritty profiles
- `waterfox` — Official Waterfox browser binaries for x86_64 and ARM64 Linux

## Run a package

```sh
nix run github:soltros/soltros_nixpkgs#addwater
nix run github:soltros/soltros_nixpkgs#pantheon-studio
nix run github:soltros/soltros_nixpkgs#termsmith
nix run github:soltros/soltros_nixpkgs#chatgpt
nix run github:soltros/soltros_nixpkgs#waterfox
nix run github:soltros/soltros_nixpkgs#flakebuilder -- --state-version 26.05
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
    termsmith
    pantheon-studio
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
nix build .#addwater
nix build .#pantheon-studio
nix build .#termsmith
nix build .#chatgpt
nix build .#waterfox
nix build .#flakebuilder
nix flake check
nix fmt
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
