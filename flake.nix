{
  description = "Personal Nix packages maintained by soltros";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      overlays.default = final: _prev: {
        chatgpt = final.callPackage ./pkgs/chatgpt.nix { };
        flakebuilder = final.callPackage ./pkgs/flakebuilder.nix { };
        flakebuilder-gui = final.callPackage ./pkgs/flakebuilder-gui.nix { };
        grayjay = _prev.grayjay;
        hideout = final.callPackage ./pkgs/hideout { };
        keyguard = _prev.keyguard;
        nixboutique = final.callPackage ./pkgs/nixboutique.nix { };
        quick-settings-tray = final.callPackage ./pkgs/quick-settings-tray { };
        termsmith = final.callPackage ./pkgs/termsmith { };
        vacuumtube = _prev.vacuum-tube;
        vpn-manager = final.callPackage ./pkgs/vpn-manager { };
        vpn-manager-deb = final.callPackage ./pkgs/vpn-manager/deb.nix { };
        waterfox = final.callPackage ./pkgs/waterfox.nix { };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs)
            chatgpt
            flakebuilder
            flakebuilder-gui
            grayjay
            hideout
            keyguard
            nixboutique
            quick-settings-tray
            termsmith
            vacuumtube
            vpn-manager
            vpn-manager-deb
            waterfox
            ;
          default = pkgs.termsmith;
        }
      );

      apps = forAllSystems (
        system: {
          check-updates = {
            type = "app";
            program = "${(nixpkgs.legacyPackages.${system}.writers.writePython3Bin "check-updates" { doCheck = false; } (builtins.readFile ./scripts/check-updates.py))}/bin/check-updates";
          };
          default = self.apps.${system}.check-updates;
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
