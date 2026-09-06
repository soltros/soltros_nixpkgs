# soltros_nixpkgs

Personal Nix packages with direct flake outputs and a reusable overlay.

## Packages

- `chatgpt` — ChatGPT desktop app for Linux
- `termsmith` — Pantheon-native launcher for reusable Alacritty profiles
- `waterfox` — Official Waterfox browser binaries for x86_64 and ARM64 Linux

## Run a package

```sh
nix run github:soltros/soltros_nixpkgs#termsmith
nix run github:soltros/soltros_nixpkgs#chatgpt
nix run github:soltros/soltros_nixpkgs#waterfox
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
    chatgpt
    termsmith
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
nix build .#termsmith
nix build .#chatgpt
nix build .#waterfox
nix flake check
nix fmt
```
