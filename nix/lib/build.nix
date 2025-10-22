# Custom package to build our piControl module against a specific kernel 
# compilation (with symvers/.config/etc)
{ pkgs, kernel, ... }:
  # We need to prepare a derivation that has Module.symvers, .config,
  # and the kernel source in one directory, then simply point our build
  # to that directory.
  let
    # Our kernel derivation has a "dev" attribute that points to the kernel headers,
    # Module.symvers, and .config files that we need
    KDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  in 
    pkgs.stdenv.mkDerivation {
      name = "piControl";
      version = "2.3.7";
      
      src = ../..;
      
      nativeBuildInputs = [
        pkgs.xz
      ];
      
      buildPhase = ''
        make KDIR=${KDIR}
        # The default RevPi image has the module compressed, so we want to do the same
        xz piControl.ko
      '';
    
      installPhase = ''
        # Use the standard depmod directory structure here, as it works for both a test
        # compile as well as including this in Nix.

        mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
        # Build our piControl module against our kernel using our flake's helper,
        # and copy it to the correct directory that will be merged into the final system's
        # modules.
        cp piControl.ko.xz $out/lib/modules/${kernel.modDirVersion}/extra/
      '';
      
      meta = with pkgs.lib; {
        description = "RevolutionPi kernel module for process image control";
        license = licenses.gpl2Only;
        platforms = [ "aarch64-linux" ];
      };
    }

