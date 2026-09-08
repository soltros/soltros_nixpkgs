{
  description = "Personal Nix packages maintained by soltros";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      nixosModules.pantheon-studio = import ./modules/pantheon-studio.nix;

      overlays.default = final: _prev: {
        addwater = final.callPackage ./pkgs/addwater { };
        chatgpt = final.callPackage ./pkgs/chatgpt.nix { };
        pantheon-studio-launcher = final.callPackage ./pkgs/pantheon-studio/launcher { };
        pantheon-studio-panel = final.callPackage ./pkgs/pantheon-studio/panel { };
        pantheon-studio = final.callPackage ./pkgs/pantheon-studio { };
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
          inherit (pkgs) addwater chatgpt pantheon-studio pantheon-studio-launcher pantheon-studio-panel termsmith waterfox;
          default = pkgs.termsmith;
        });

      checks = forAllSystems (system:
        let
          desktop = nixpkgs.lib.nixosSystem {
            modules = [ self.nixosModules.pantheon-studio {
              nixpkgs.hostPlatform = system;
              services.desktopManager.pantheon.enable = true;
              programs.pantheon-studio.enable = true;
            } ];
          };
          panel = desktop.pkgs.pantheon.wingpanel-with-indicators;
        in {
          addwater = self.packages.${system}.addwater;
          pantheon-studio = self.packages.${system}.pantheon-studio;
          launcher = self.packages.${system}.pantheon-studio-launcher;
          panel = self.packages.${system}.pantheon-studio-panel;
          desktop-integration =
            assert desktop.pkgs.pantheon.wingpanel.pname == "wingpanel-studio";
            assert desktop.pkgs.pantheon.wingpanel-applications-menu.pname == "wingpanel-applications-menu-studio";
            assert builtins.any (p: p.pname == "wingpanel-studio") panel.paths;
            assert builtins.any (p: p.pname == "wingpanel-applications-menu-studio") panel.paths;
            nixpkgs.legacyPackages.${system}.runCommand "studio-module-check" { } "touch $out";
        });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
