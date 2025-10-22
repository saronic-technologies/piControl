{ nixpkgs, flake-utils, ...}:
let
  # The shell only works on Linux for now as we need
  # to compile our module against the kernel headers, which
  # can only be done on Linux.
  system = flake-utils.lib.system.aarch64-linux;
  pkgs = import nixpkgs { inherit system; };

  # We use these to build our compile_commands.json file
  revpi-kernel-headers = pkgs.stdenv.mkDerivation {
    name = "revpi-kernel-headers";

    src = pkgs.fetchFromGitHub {
      owner = "saronic-technologies";
      repo = "linux-headers-6.6.0-revpi6-rpi-v8";
      rev = "ce6151e08909682291571f800104af92895aaeab";
      hash = "sha256-G2QhZGtUaXbPS+Anex0Hv9Ogbx7kExXqYeFsDXBWbmU=";
    };

    nativeBuildInputs = with pkgs; [
      patchelf
    ];

    # We need this for some reason, as Nix tries to build the headers otherwise
    buildPhase = ''
      echo "Dummy"
    '';
    # Copy all the header information into the $out directory
    installPhase = ''
      mkdir -p $out
      cp -R . $out
      NIX_DYNAMIC_LINKER=$(cat $NIX_CC/nix-support/dynamic-linker)
      # Patch our fixdep interpreter to use our dynamic linker instead of the one it was compiled for
      patchelf --set-interpreter "$NIX_DYNAMIC_LINKER" $out/scripts/basic/fixdep
      # Patch our modpost interpreter to use our dynamic linker instead of the one it was compiled for
      patchelf --set-interpreter "$NIX_DYNAMIC_LINKER" $out/scripts/mod/modpost
    '';
  };
in 
{
  devShells.${system}.default = pkgs.mkShell {
    packages = with pkgs; [
      gnumake
      gcc
      bc
      flex
      bison
      elfutils
      openssl
      pkg-config
      ncurses
      perl
      bear
    ];
    
    shellHook = ''
      # Create kernel source symlink in a known location
      
      # compile_commands.json only works when made in this directory for some reason, which sucks
      make KDIR=${revpi-kernel-headers} clean
      bear -- make KDIR=${revpi-kernel-headers} V=1
      
      # Remove problematic -mabi=lp64 flag
      sed -i 's/"-mabi=lp64",//g' compile_commands.json
    '';
  };

}
