{ config, lib, pkgs, ... }:
{
  options.programs.pantheon-studio.enable = lib.mkEnableOption "Pantheon Studio with launcher and panel integration";
  config = lib.mkIf config.programs.pantheon-studio.enable {
    assertions = [ {
      assertion = config.services.desktopManager.pantheon.enable;
      message = "Pantheon Studio launcher integration requires the Pantheon desktop.";
    } ];
    nixpkgs.overlays = [ (final: prev: {
      pantheon = prev.pantheon.overrideScope (_pFinal: pPrev: {
        wingpanel = final.callPackage ../pkgs/pantheon-studio/panel { pantheon = pPrev; };
        wingpanel-applications-menu = final.callPackage ../pkgs/pantheon-studio/launcher {
          pantheon = pPrev;
        };
      });
    }) ];
    environment.systemPackages = [ (pkgs.callPackage ../pkgs/pantheon-studio { }) ];
  };
}
