# Derivation just to track the kernel we want to use with our module,
# as it will change as the module changes as well, so we want it in 
# a consistent place for both compile_commands and our module.
{ nixpkgs, flake-utils, ... }:
let
  system = flake-utils.lib.system.aarch64-linux;
  pkgs = import nixpkgs { inherit system; };
in 
  pkgs.buildLinux {
    version = "6.6.84-rt52-v8";
    # modDirVersion = "6.6.84-rt52-v8";
  
    src = pkgs.fetchFromGitLab {
      owner = "revolutionpi";
      repo = "linux";
      rev = "e7b2a4abc38f473957d2bacac57a2ce9bb06613a";
      hash = "sha256-AAAAos2FpDpagbY8n7gaMsJWuyBHwjottOX5AHVgCmI=";
    };
      # src = pkgs.fetchFromGitHub {
      #   owner = "RevolutionPi";
      #   repo = "linux";
      #   rev = "26e35e95be0aa35823039d049034daaf3fdc4287";
      #   hash = "sha256-K5uVos2FpDpagbY8n7gaMsJWuyBHwjottOX5AHVgCmI=";
      #   # rev = "fe0aa6034a477f1ee3c68843beebbf31b4c0c8cb";
      #   # hash = "sha256-K0UiPuOs7OOmzLVoNm31sMgTS9ImVhV5R98jSMa41qc=";
      # };
  
    # This line forces Nix to see "rev" as semantically relevant
    NIX_FORCE_KERNEL_REV = "e7b2a4abc38f473957d2bacac57a2ce9bb06613a";
    # NIX_FORCE_KERNEL_REV = "26e35e95be0aa35823039d049034daaf3fdc4287";

    autoModules = false;
  
    # !!! This doesn't work in nixpkgs stable, only in unstable.
    # !!! In stable, we would get an error as the common config is erroneously
    # !!! being included.
    enableCommonConfig = false;
  
    defconfig = "revpi-v8_defconfig";
  
    structuredExtraConfig = {};
  }

