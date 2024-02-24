{ inputs, ... }:
let
  inherit (inputs.self.lib) nixosSystem;
  inherit (inputs.nixpkgs.lib) makeOverridable;

  buildX86_64 = name: makeOverridable nixosSystem {
    # TODO: jakos lepiej
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [ ./${name}/configuration.nix ];
  };

  hosts = builtins.removeAttrs (builtins.readDir ./.) [ "default.nix" ];
in
builtins.mapAttrs (name: value: (buildX86_64 name)) hosts