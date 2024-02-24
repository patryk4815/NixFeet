{
#  nixConfig.extra-substituters = [
#    "https://todo.pl"
#  ];
#  nixConfig.extra-trusted-public-keys = [
#    "todo.pl-1:1337+/1337="
#  ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-images = {
      url = "github:nix-community/nixos-images";
    };

  };

  outputs = inputs @ { flake-parts, self, ... }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

        perSystem = { config, inputs', lib, pkgs, self', system, ... }: let
          systemCross = if pkgs.stdenv.isLinux then system else "x86_64-linux";
          kexec-installer = nixpkgs: modules: (nixpkgs.legacyPackages.${systemCross}.nixos (modules ++ [
            inputs.nixos-images.nixosModules.kexec-installer
          ])).config.system.build.kexecTarball;
#          netboot-installer = nixpkgs: (nixpkgs.legacyPackages.${system}.nixos [ inputs.nixos-images.nixosModules.netboot-installer ]).config.system.build.netboot;
        in {
          imports = [
            ./dev/shell.nix
          ];

          packages = {
            kexec-installer-nixos-noninteractive = kexec-installer inputs.nixpkgs [
              {
                system.kexec-installer.name = "nixos-kexec-installer-noninteractive";
              }
              inputs.nixos-images.nixosModules.noninteractive
#              self.nixosModules.custom
            ];
          };
        };

        flake.darwinConfigurations = {};  # TODO: darwin
        flake.nixosConfigurations = import ./hosts { inherit inputs; };

        flake.darwinModules = import ./modules/darwin;
        flake.nixosModules = import ./modules/nixos;

        flake.lib.darwinSystem = args: inputs.nix-darwin.lib.darwinSystem ({ specialArgs = { inherit inputs; }; } // args);
        flake.lib.nixosSystem = args: inputs.nixpkgs.lib.nixosSystem ({ specialArgs = { inherit inputs; }; } // args);
      };
}