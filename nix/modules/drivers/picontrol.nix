{ ... }:
{ config, pkgs, lib, ... }:
let
  cfg = config.picontrol;
in 
{
  options = {
    picontrol = {
      enable = lib.mkEnableOption "picontrol-module";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      # Build our piControl module with our configuration's kernel, and
      # include it in our extra kernel packages.
      extraModulePackages = [
        ((pkgs.callPackage ../../lib/build.nix) { kernel = config.boot.kernelPackages.kernel; })
      ];
      # Include our piControlModule in our kernelModules, so it is loaded at boot
      kernelModules = [ "piControl" ];
    };    
  };
}
