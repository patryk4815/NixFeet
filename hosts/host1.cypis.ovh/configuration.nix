
{ inputs, pkgs, lib, config, ... }:
{
  imports = [
    # ./hardware-configuration.nix # auto generate by command: inv ssh-hardware --hostname root@1.1.1.1
    # ./networking.nix  # auto generate by command: inv ssh-networking --hostname root@1.1.1.1
    inputs.self.nixosModules.common
    inputs.self.nixosModules.disko
  ];

  system.stateVersion = "23.11";  # Don't change after deploy! Read docs.
}