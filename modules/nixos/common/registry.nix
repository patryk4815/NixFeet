{ inputs, lib, config, ... }:
{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  system.extraSystemBuilderCmds = ''
    ln -s ${inputs.self} $out/flake
  '';

  nix.extraOptions = ''
    experimental-features = nix-command flakes
    flake-registry = file://${./flake-registry.json}
  '';
}