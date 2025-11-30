{ nixpkgs, flake-utils, ...}@inputs:
let
  kernel = import ../lib/kernel.nix inputs;
  compile_commands = import ./compile_commands.nix inputs;
in 
  flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = import nixpkgs { inherit system; };
  in 
  {
    devShells.default = pkgs.mkShell {
      shellHook = ''
        rm -rf compile_commands.json
        ln -s ${compile_commands kernel}/compile_commands.json compile_commands.json
      '';
    };
  })
