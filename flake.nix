{
  description = "RevolutionPi kernel module development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };
      
      revpi-kernel-prepared = pkgs.stdenv.mkDerivation {
        name = "revpi-kernel-prepared";

        src = pkgs.fetchFromGitHub {
          owner = "RevolutionPi";
          repo = "linux";
          rev = "revpi-6.1";
          hash = "sha256-2CdHDlbnkFi+ehFNmiJhGy0T77xf2Fc2qS3jYFXwljA=";
        };

        nativeBuildInputs = with pkgs; [
          gcc
          bc
          flex
          bison
          elfutils
          openssl
          pkg-config
          ncurses
          perl
        ];

        buildPhase = ''
          # Prepare the kernel for module building
          make mrproper
          make defconfig
          make modules_prepare
        '';
        installPhase = ''
          mkdir -p $out
          cp -R . $out
        '';
      };

      # Build script for kernel module
      build-module = pkgs.writeShellScriptBin "build-module" ''
        make KDIR=${revpi-kernel-prepared} clean
        make KDIR=${revpi-kernel-prepared} "$@"
      '';

      # Package for the kernel module
      piControl = pkgs.stdenv.mkDerivation {
        name = "piControl";
        version = "2.3.7";
        
        src = ./.;
        
        nativeBuildInputs = [
          build-module
        ];
        
        # !!! I have no idea why I can't just build this using exactly what build-module
        # !!! does!  This is working for now, so I'm going to leave it as-is
        buildPhase = ''
          build-module
        '';

        installPhase = ''
          mkdir -p $out
          cp piControl.ko $out/
        '';
        
        meta = with pkgs.lib; {
          description = "RevolutionPi kernel module for process image control";
          license = licenses.gpl2Only;
          platforms = [ "aarch64-linux" ];
        };
      };
    in
    {
      packages.${system}.default = piControl;
      
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
          build-module
        ];
        
        shellHook = ''
          # Create kernel source symlink in a known location
          KERNEL_SRC="$HOME/.cache/revpi-kernel"
          mkdir -p "$(dirname "$KERNEL_SRC")"
          if [ ! -e "$KERNEL_SRC" ]; then
            ln -sf ${revpi-kernel-prepared} "$KERNEL_SRC"
          fi
          
          # Set KDIR for module compilation
          export KDIR="$KERNEL_SRC"
          
          # compile_commands.json only works when made in this directory for some reason, which sucks
          make KDIR=${revpi-kernel-prepared} clean
          bear -- make KDIR=${revpi-kernel-prepared} V=1
          
          # Remove problematic -mabi=lp64 flag
          sed -i 's/"-mabi=lp64",//g' compile_commands.json

          echo "RevolutionPi kernel source symlinked to: $KERNEL_SRC"
          echo "To build the module, run: build-module"
        '';
      };
    };
}

