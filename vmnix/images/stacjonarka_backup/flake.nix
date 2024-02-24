{
  description = "conf";

  inputs = {
    nixpkgs.url = "git+file:///etc/nix/nixpkgs";
  };

  outputs = { self, nixpkgs }:
    let
      x = 1;
    in {

    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
        }
        ./configuration.nix
      ];
    };

  };
}
