{ nixpkgs, flake-utils, ...}@inputs:
let
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
        ln -s ${compile_commands}/compile_commands.json compile_commands.json
      '';
    };
  })
