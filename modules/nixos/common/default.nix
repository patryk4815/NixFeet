{ inputs, pkgs, lib, config, ... }:
{
  imports = [
    ./fqdn.nix
    ./diff.nix
    ./nix-index.nix
    ./registry.nix
    ./sops-nix.nix
    inputs.sops-nix.nixosModules.sops
  ];

  environment.systemPackages = map lib.lowPrio [
    pkgs.htop
    pkgs.jq
    pkgs.tmux
    pkgs.curl
    pkgs.gitMinimal
  ];

  services.openssh.enable = true;

  users.mutableUsers = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # TODO: auto nix gc
  # TODO: auto upgrade / auto reboot if kernel change
  # TODO: auto backup (btrbk or borgbackup)
}