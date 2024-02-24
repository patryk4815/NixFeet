{
  description = "conf";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      x = 1;
    in {

    nixosConfigurations."rpi.cypis.ovh" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        {
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
        }
        ./configuration.nix
      ];
    };

  };
}
