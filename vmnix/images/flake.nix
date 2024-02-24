{
  description = "Build image";

  inputs = {
    nixpkgs_armv7.url = "git+file:///Users/psondej/projekty/nixpkgs_armv7";
    nixpkgs_aarch64.url = "git+file:///Users/psondej/projekty/nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs_armv7, nixpkgs_aarch64, nixpkgs, darwin }:
    let
      x = 1;

#  fileSystems."/mnt/dnif" = {
 #    device = "/dev/vda1";
 #    fsType = "ext4";
 #    neededForBoot = false;
 #    options = [ "noatime" ];
 #  };
 #
 #  fileSystems."/DNIF" = {
 #    device = "/mnt/dnif/DNIF";
 #    options = [ "bind" "noatime" ];
 #  };
 #
 #  fileSystems."/var/lib/docker" = {
 #    device = "/mnt/dnif/docker";
 #    options = [ "bind" "noatime" ];
 #  };
 #
 #  fileSystems."/var/lib/clickhouse" = {
 #    device = "/mnt/dnif/clickhouse";
 #    options = [ "bind" "noatime" ];
 #  };
 # services.xserver = {
    #enable = true;
    #displayManager.lightdm.enable = true;
    #    desktopManager.xterm.enable = false;
    #    desktopManager.xfce.enable = true;
    #    displayManager.defaultSession = "xfce";
    #};
    #services.openssh.forwardX11 = true;
    #programs.ssh.setXAuthLocation = true;

      overlay = final: prev: {
        # big bugged version :(
        zsh-autocomplete = prev.zsh-autocomplete.overrideAttrs (oldAttrs: rec {
          version = "main";
          src = prev.fetchFromGitHub {
            owner = "marlonrichert";
            repo = "zsh-autocomplete";
            rev = "d00142dd752c15aaa775d79c61ff0611acf20bad";
            sha256 = "sha256-0yzqbX39hqsE2mAXFY3uoK5zrcm0uZmsTr+dB8keFIs=";
          };
        });
      };
    in {
    nixosConfigurations.armv7_sdImage = nixpkgs_armv7.lib.nixosSystem {
      #system = "armv7l-linux";
      system = "aarch64-linux";
      modules = [
        "${nixpkgs_armv7}/nixos/modules/installer/sd-card/sd-image-armv7l-multiplatform.nix"
        ./banana_pi.nix
      ];
    };
    nixosConfigurations.aarch64_sdImage = nixpkgs_aarch64.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs_aarch64}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./rpi.nix
      ];
    };
    images.babanaPi = self.nixosConfigurations.armv7_sdImage.config.system.build.sdImage;
    images.rpi = self.nixosConfigurations.aarch64_sdImage.config.system.build.sdImage;

    # FIXME: remove to tylko testowo cross
    nixosConfigurations."rpi.cypis.ovh" = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.localSystem = { system = "x86_64-linux"; };
          nixpkgs.crossSystem = { system = "aarch64-linux"; };
        })
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ./rpi.nix
      ];
    };
    images.rpi2 = self.nixosConfigurations."rpi.cypis.ovh".config.system.build.sdImage;


    darwinConfigurations."MacBook-Pro-patryk" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ {
        nixpkgs.overlays = [ overlay ];
        nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
      } ] ++ nixpkgs.lib.attrValues self.darwinModules ++ [ ./configuration.nix ];
    };

    darwinModules = {
    };

  };
}