{
  description = "RevolutionPi kernel module development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs { inherit system; };

      inherit (nixpkgs) lib;
      
      sample_kernel = pkgs.buildLinux {
        version = "6.6.84-rt52-v8";
        # extraMeta.branch = "6.6";
      
        src = pkgs.fetchFromGitHub {
          owner = "RevolutionPi";
          repo = "linux";
          rev = "fe0aa6034a477f1ee3c68843beebbf31b4c0c8cb";
          hash = "sha256-K0UiPuOs7OOmzLVoNm31sMgTS9ImVhV5R98jSMa41qc=";
        };
      
        autoModules = false;
      
        enableCommonConfig = false;
        # ignoreConfigErrors = true;
      
        # features = { };
      
        # kernelPatches = [ ] ++ kernelPatches;
      
        defconfig = "revpi-v8_defconfig";
      
        # We will disable pieces of the kernel here for "release" builds
        structuredExtraConfig = {
        };
      };
      # revpi-kernel-prepared = pkgs.stdenv.mkDerivation {
      #   name = "revpi-kernel-prepared";

      #   src = pkgs.fetchFromGitHub {
      #     owner = "RevolutionPi";
      #     repo = "linux";
      #     rev = "revpi-6.6";
      #     hash = "sha256-nubcbFtByYeT7Qcozi8tgIMyPwkZAF7SHq/QeT03GrI=";
      #   };

      #   nativeBuildInputs = with pkgs; [
      #     gcc12
      #     bc
      #     flex
      #     bison
      #     elfutils
      #     openssl
      #     pkg-config
      #     ncurses
      #     perl
      #   ];

      #   buildPhase = ''
      #     # Prepare the kernel for module building
      #     make mrproper
      #     cp ${revpi-kernel-headers}/.config .
      #     make modules_prepare
      #     cp ${revpi-kernel-headers}/Module.symvers .
      #   '';
      #   installPhase = ''
      #     mkdir -p $out
      #     cp -R . $out
      #   '';
      # };

      # Derivation to get Modules.symvers and .config for the RevPi that we are
      # using.  It's RevPi Linux dependent; we are using 6.6 right now
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

      # Package for the kernel module
      # piControl = pkgs.stdenv.mkDerivation {
      #   name = "piControl";
      #   version = "2.3.7";
      #   
      #   src = ./.;
      #   
      #   nativeBuildInputs = [
      #     pkgs.xz
      #   ];
      #   
      #   buildPhase = ''
      #     make KDIR=${revpi-kernel-headers}
      #     # The default RevPi image has the module compressed, so we want to do the same
      #     xz piControl.ko
      #   '';

      #   installPhase = ''
      #     mkdir -p $out
      #     cp piControl.ko.xz $out/
      #   '';
      #   
      #   meta = with pkgs.lib; {
      #     description = "RevolutionPi kernel module for process image control";
      #     license = licenses.gpl2Only;
      #     platforms = [ "aarch64-linux" ];
      #   };
      # };
    in
    {
      buildWithKernel = kernel: (
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
            
            src = ./.;
            
            nativeBuildInputs = [
              pkgs.xz
            ];
            
            buildPhase = ''
              make KDIR=${KDIR}
              # The default RevPi image has the module compressed, so we want to do the same
              xz piControl.ko
            '';
          
            installPhase = ''
              mkdir -p $out
              cp piControl.ko.xz $out/
            '';
            
            meta = with pkgs.lib; {
              description = "RevolutionPi kernel module for process image control";
              license = licenses.gpl2Only;
              platforms = [ "aarch64-linux" ];
            };
          }
      );
      packages.${system} = {
        default = (self.buildWithKernel sample_kernel);
        sample_kernel = sample_kernel;
      };
      
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
    };
}

