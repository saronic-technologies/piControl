{
  description = "RevolutionPi kernel module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { flake-utils, ... }@inputs:
    flake-utils.lib.meld inputs [
      ./nix/modules
      ./nix/shells
      ./nix/packages
    ];
}

