{ nixpkgs, flake-utils, ...}:
let
  system = flake-utils.lib.system.aarch64-linux;
  pkgs = import nixpkgs { inherit system; };
  # We have a sample kernel here which we use for testing.
  # !!! If we modify our kernel, we need to change this target, so
  # !!! the sooner we fork into our own repo, the better.
  sample_kernel = pkgs.buildLinux {
    version = "6.6.84-rt52-v8";
  
    src = pkgs.fetchFromGitHub {
      owner = "RevolutionPi";
      repo = "linux";
      rev = "fe0aa6034a477f1ee3c68843beebbf31b4c0c8cb";
      hash = "sha256-K0UiPuOs7OOmzLVoNm31sMgTS9ImVhV5R98jSMa41qc=";
    };
  
    autoModules = false;
  
    # !!! This doesn't work in nixpkgs stable, only in unstable.
    # !!! In stable, we would get an error as the common config is erroneously
    # !!! being included.
    enableCommonConfig = false;
  
    defconfig = "revpi-v8_defconfig";
  
    structuredExtraConfig = {};
  };
in 
{
  packages.${system} = {
    # Test build just to test our piControl compilation and make sure there are no
    # errors and it can compile against a kernel
    testBuild = ((pkgs.callPackage ../lib/build.nix) { kernel = sample_kernel; });
  };
}
