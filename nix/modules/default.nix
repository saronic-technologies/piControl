{ flake-utils, ... }@inputs:
{
  nixosModules = flake-utils.lib.meld inputs [
    ./drivers
  ];
}
