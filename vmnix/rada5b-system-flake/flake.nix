{
  description = "A very basic flake";

#  nixConfig = {
#    extra-substituters = ["https://rock5b-nixos.cachix.org"];
#    extra-trusted-public-keys = ["rock5b-nixos.cachix.org-1:bXHDewFS0d8pT90A+/YZan/3SjcyuPZ/QRgRSuhSPnA="];
#  };

  inputs = {
    rock5b-nixos.url = "github:patryk4815/rock5b-nixos";
    nixpkgs.follows = "rock5b-nixos/nixpkgs";  # hmm
  };

  outputs = { self, nixpkgs, rock5b-nixos }: {
    nixosConfigurations = {
      rock5b = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          {
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
          }
          rock5b-nixos.nixosModules.kernel
          rock5b-nixos.nixosModules.fan-control
          ./configuration.nix
        ];
      };
    };
  };
}