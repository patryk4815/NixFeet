{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  services.spice-vdagentd.enable = true;

  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  networking.firewall.enable = false;

  nix.package = pkgs.nixUnstable;

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    group = lib.mkForce "root";
    hosts = lib.mkForce [ "0.0.0.0:1111" ];
  };

  environment.interactiveShellInit = ''
    export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
    export HISTSIZE=100000                   # big big history
    export HISTFILESIZE=100000               # big big history
    shopt -s histappend                      # append to history, don't overwrite it

    # Save and reload the history after each command finishes
    export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
  '';

  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspend=no
  '';

  nix.extraOptions = ''
experimental-features = nix-command flakes repl-flake
  '';

  fileSystems."/Users" = {
    device = "share";
    fsType = "virtiofs";
  };

  boot.initrd.availableKernelModules = [ "virtiofs" ];
  fileSystems."/run/rosetta" = {
    device = "rosetta";
    fsType = "virtiofs";
  };
  nix.settings.extra-platforms = [ "x86_64-linux" ];
  nix.settings.extra-sandbox-paths = [ "/run/rosetta" "/run/binfmt" ];

  boot.binfmt.registrations."rosetta" = {
    interpreter = "/run/rosetta/rosetta";
    fixBinary = true;
    wrapInterpreterInShell = false;
    matchCredentials = true;
    magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
    mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
  };

}