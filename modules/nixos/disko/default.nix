{ inputs, lib, config, ... }:
{
  imports = [
    inputs.disko.nixosModules.default
  ];

  options = {
    nixCommunity.disko.device = lib.mkOption {
      type = lib.types.str;
      default = throw "nixCommunity.disko.device Set this to your disk device, e.g. /dev/sda or /dev/vda";
      description = "Set this to your disk device";
    };
  };

  config = {
    # only efi
#    boot.loader.systemd-boot.enable = true;
#    boot.loader.efi.canTouchEfiVariables = true;

    # bios + efi
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
#    boot.loader.systemd-boot.configurationLimit = 10;
#    boot.loader.timeout = 3;

    disko.devices = {
      disk.main = {
        device = config.nixCommunity.disko.device;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "4G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "root_vg";
              };
            };
          };
        };
      };
      lvm_vg = {
        root_vg = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%FREE";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];

                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                  };

                  "/persist" = {
                    mountOptions = ["subvol=persist" "noatime"];
                    mountpoint = "/persist";
                  };

                  "/nix" = {
                    mountOptions = ["subvol=nix" "noatime"];
                    mountpoint = "/nix";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}