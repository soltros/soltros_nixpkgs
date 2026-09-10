{
  description = "Personal Nix packages maintained by soltros";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      overlays.default = final: _prev: {
        chatgpt = final.callPackage ./pkgs/chatgpt.nix { };
        flakebuilder = final.callPackage ./pkgs/flakebuilder.nix { };
        flakebuilder-gui = final.callPackage ./pkgs/flakebuilder-gui.nix { };
        termsmith = final.callPackage ./pkgs/termsmith { };
        waterfox = final.callPackage ./pkgs/waterfox.nix { };
      };

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in {
          inherit (pkgs) chatgpt flakebuilder flakebuilder-gui termsmith waterfox;
          default = pkgs.termsmith;
        });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
